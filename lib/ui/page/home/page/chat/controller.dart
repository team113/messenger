// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' hide ChatItemQuoteInput;
import '/domain/model/application_settings.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/settings.dart';
import '/domain/repository/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show
        ConnectionException,
        DeleteChatForwardException,
        DeleteChatMessageException,
        EditChatMessageException,
        HideChatItemException,
        PostChatMessageException,
        ReadChatException,
        UploadAttachmentException;
import '/routes.dart';
import '/ui/page/home/page/user/controller.dart';
import '/util/audio_utils.dart';
import '/util/log.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'forward/view.dart';
import 'message_field/controller.dart';
import 'view.dart';
import 'widget/chat_gallery.dart';

export 'view.dart';

/// Controller of the [Routes.chats] page.
class ChatController extends GetxController {
  ChatController(
    this.id,
    this._chatService,
    this._callService,
    this._authService,
    this._userService,
    this._settingsRepository, {
    this.itemId,
  });

  /// ID of this [Chat].
  ChatId id;

  /// [RxChat] of this page.
  RxChat? chat;

  /// ID of the [ChatItem] to scroll to initially in this [ChatView].
  final ChatItemId? itemId;

  /// Indicator whether the down FAB should be visible.
  final RxBool canGoDown = RxBool(false);

  /// Indicator whether the return FAB should be visible.
  final RxBool canGoBack = RxBool(false);

  /// Indicator whether any [Text] is being selected right now.
  ///
  /// Used to discard [SwipeableStatus] gestures when [Text] is being selected.
  final RxBool isSelecting = RxBool(false);

  /// Index of a [ChatItem] in a [FlutterListView] that should be visible on
  /// initialization.
  int initIndex = 0;

  /// Offset that should be applied to a [FlutterListView] on initialization.
  double initOffset = 0;

  /// Status of a [chat] fetching.
  ///
  /// May be:
  /// - `status.isLoading`, meaning [chat] is being fetched from the service.
  /// - `status.isEmpty`, meaning [chat] with specified [id] was not found.
  /// - `status.isSuccess`, meaning [chat] is successfully fetched.
  Rx<RxStatus> status = Rx<RxStatus>(RxStatus.loading());

  /// [RxObsSplayTreeMap] of the [ListElement]s to display.
  final RxObsSplayTreeMap<ListElementId, ListElement> elements =
      RxObsSplayTreeMap();

  /// [MessageFieldController] for sending a [ChatMessage].
  late final MessageFieldController send;

  /// [MessageFieldController] for editing a [ChatMessage].
  final Rx<MessageFieldController?> edit = Rx(null);

  /// [SelectedContent] of a [SelectionArea] within this [ChatView].
  final Rx<SelectedContent?> selection = Rx(null);

  /// Interval of a [ChatMessage] since its creation within which this
  /// [ChatMessage] is allowed to be edited.
  static const Duration editMessageTimeout = Duration(minutes: 5);

  /// Bottom offset to apply to the last [ListElement] in the [elements].
  static const double lastItemBottomOffset = 10;

  /// [FlutterListViewController] of a messages [FlutterListView].
  final FlutterListViewController listController = FlutterListViewController();

  /// Indicator whether there is an ongoing drag-n-drop at the moment.
  final RxBool isDraggingFiles = RxBool(false);

  /// Indicator whether any [ChatItem] is being dragged.
  ///
  /// Used to discard any horizontal gestures while this is `true`.
  final RxBool isItemDragged = RxBool(false);

  /// Summarized [Offset] of an ongoing scroll.
  Offset scrollOffset = Offset.zero;

  /// Indicator whether an ongoing horizontal scroll is happening.
  ///
  /// Used to discard any vertical gestures while this is `true`.
  final RxBool isHorizontalScroll = RxBool(false);

  /// [Timer] for discarding any vertical movement in a [FlutterListView] of
  /// [ChatItem]s when non-`null`.
  final Rx<Timer?> horizontalScrollTimer = Rx(null);

  /// Maximum [Duration] between some [ChatForward]s to consider them grouped.
  static const Duration groupForwardThreshold = Duration(milliseconds: 5);

  /// Count of [ChatItem]s unread by the authenticated [MyUser] in this [chat].
  int unreadMessages = 0;

  /// Sticky element index of a [FlutterListView] currently being visible.
  final RxnInt stickyIndex = RxnInt(null);

  /// Indicator whether sticky header should be visible or not.
  ///
  /// Used to hide it when no scrolling is happening.
  final RxBool showSticky = RxBool(false);

  /// Keep position offset of the [FlutterListViewDelegate].
  ///
  /// Position is kept only when `scrollOffset` >= [keepPositionOffset].
  final Rx<double> keepPositionOffset = Rx(20);

  /// Indicator whether the [LoaderElement]s should be displayed.
  final RxBool showLoaders = RxBool(true);

  /// Indicator whether the application is active.
  final RxBool active = RxBool(true);

  /// Height of a [LoaderElement] displayed in the message list.
  static const double loaderHeight = 64;

  /// Index of an item from the [elements] that should be highlighted.
  final RxnInt highlightIndex = RxnInt(null);

  /// Top visible [FlutterListViewItemPosition] in the [FlutterListView].
  FlutterListViewItemPosition? _topVisibleItem;

  /// [FlutterListViewItemPosition] of the bottom visible item in the
  /// [FlutterListView].
  FlutterListViewItemPosition? _lastVisibleItem;

  /// First [ChatItem] unread by the authenticated [MyUser] in this [Chat].
  ///
  /// Used to scroll to it when [Chat] messages are fetched and to properly
  /// place the unread messages badge in the [elements] list.
  Rx<ChatItem>? _firstUnread;

  /// [FlutterListViewItemPosition] of the [ChatItem] to return to when the
  /// return FAB is pressed.
  FlutterListViewItemPosition? _itemToReturnTo;

  /// [ChatItem] with the latest [ChatItem.at] visible on the screen.
  ///
  /// Used to [readChat] up to this message.
  final Rx<ChatItem?> _lastSeenItem = Rx<ChatItem?>(null);

  /// [Duration] considered as a timeout of the ongoing typing.
  static const Duration _typingDuration = Duration(seconds: 3);

  /// [StreamSubscription] to [ChatService.keepTyping] indicating an ongoing
  /// typing in this [chat].
  StreamSubscription? _typingSubscription;

  /// Subscription for the [RxChat.messages] updating the [elements].
  StreamSubscription? _messagesSubscription;

  /// Subscription to the [PlatformUtils.onActivityChanged] updating the
  /// [active].
  StreamSubscription? _onActivityChanged;

  /// Indicator whether [_updateFabStates] should not be react on
  /// [FlutterListViewController.position] changes.
  bool _ignorePositionChanges = false;

  /// Currently displayed [UnreadMessagesElement] in the [elements] list.
  UnreadMessagesElement? _unreadElement;

  /// Currently displayed [LoaderElement] in the top of the [elements] list.
  LoaderElement? _topLoader;

  /// Currently displayed [LoaderElement] in the bottom of the [elements] list.
  LoaderElement? _bottomLoader;

  /// [Timer] canceling the [_typingSubscription] after [_typingDuration].
  Timer? _typingTimer;

  /// [Timer] for resetting the [showSticky].
  Timer? _stickyTimer;

  /// Call service used to start the call in this [Chat].
  final CallService _callService;

  /// [Chat]s service used to get [chat] value.
  final ChatService _chatService;

  /// [AuthService] used to get [me] value.
  final AuthService _authService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// [AbstractSettingsRepository], used to get the [background] value.
  final AbstractSettingsRepository _settingsRepository;

  /// Worker performing a [readChat] on [lastVisible] changes.
  Worker? _readWorker;

  /// Worker performing a jump to the last read message on a successful
  /// [RxChat.status].
  Worker? _messageInitializedWorker;

  /// Worker capturing any [RxChat.chat] changes.
  Worker? _chatWorker;

  /// Worker capturing any [status] changes.
  Worker? _statusWorker;

  /// [Duration] of the highlighting.
  static const Duration _highlightTimeout = Duration(seconds: 1);

  /// [Timer] resetting the [highlightIndex] value after the [_highlightTimeout]
  /// has passed.
  Timer? _highlightTimer;

  /// [Timer] adding the [_bottomLoader] to the [elements] list.
  Timer? _bottomLoaderStartTimer;

  /// [Timer] deleting the [_bottomLoader] from the [elements] list.
  Timer? _bottomLoaderEndTimer;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Returns the [Uint8List] of the background.
  Rx<Uint8List?> get background => _settingsRepository.background;

  /// Returns the [ApplicationSettings].
  Rx<ApplicationSettings?> get settings =>
      _settingsRepository.applicationSettings;

  /// Indicates whether this device of the currently authenticated [MyUser]
  /// takes part in the [Chat.ongoingCall], if any.
  bool get inCall =>
      _callService.calls[id] != null || WebUtils.containsCall(id);

  /// Indicates whether a previous page of the [elements] is exists.
  RxBool get hasPrevious => chat!.hasPrevious;

  /// Indicates whether a next page of the [elements] is exists.
  RxBool get hasNext => chat!.hasNext;

  /// Indicates whether the [listController] is scrolled to its bottom.
  bool get _atBottom =>
      listController.hasClients && listController.position.pixels < 500;

  /// Indicates whether the [listController] is scrolled to its top.
  bool get _atTop =>
      listController.hasClients &&
      listController.position.pixels >
          listController.position.maxScrollExtent - 500;

  @override
  void onInit() {
    send = MessageFieldController(
      _chatService,
      _userService,
      onChanged: updateDraft,
      onSubmit: () async {
        if (send.forwarding.value) {
          if (send.replied.isNotEmpty) {
            if (send.replied.any((e) => e is ChatCall)) {
              MessagePopup.error('err_cant_forward_calls'.l10n);
              return;
            }

            bool? result = await ChatForwardView.show(
              router.context!,
              id,
              send.replied.map((e) => ChatItemQuoteInput(item: e)).toList(),
              text: send.field.text,
              attachments: send.attachments.map((e) => e.value).toList(),
            );

            if (result == true) {
              send.clear();
            }
          }
        } else {
          if (send.field.text.trim().isNotEmpty ||
              send.attachments.isNotEmpty ||
              send.replied.isNotEmpty) {
            _chatService
                .sendChatMessage(
                  chat!.chat.value.id,
                  text: send.field.text.trim().isEmpty
                      ? null
                      : ChatMessageText(send.field.text.trim()),
                  repliesTo: send.replied.reversed.toList(),
                  attachments: send.attachments.map((e) => e.value).toList(),
                )
                .then((_) => AudioUtils.once(
                    AudioSource.asset('audio/message_sent.mp3')))
                .onError<PostChatMessageException>(
                    (e, _) => MessagePopup.error(e))
                .onError<UploadAttachmentException>(
                    (e, _) => MessagePopup.error(e))
                .onError<ConnectionException>((e, _) {});

            send.clear();

            chat?.setDraft();

            _typingSubscription?.cancel();
            _typingSubscription = null;
            _typingTimer?.cancel();

            if (!PlatformUtils.isMobile) {
              Future.delayed(Duration.zero, send.field.focus.requestFocus);
            }
          }
        }
      },
    );

    PlatformUtils.isActive.then((value) => active.value = value);
    _onActivityChanged = PlatformUtils.onActivityChanged.listen((v) {
      active.value = v;

      if (v) {
        readChat(_lastSeenItem.value);
      }
    });

    super.onInit();
  }

  @override
  void onReady() {
    listController.addListener(_listControllerListener);
    listController.sliverController.stickyIndex.addListener(_updateSticky);
    AudioUtils.ensureInitialized();
    _fetchChat();
    super.onReady();
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    _readWorker?.dispose();
    _chatWorker?.dispose();
    _statusWorker?.dispose();
    _typingSubscription?.cancel();
    _onActivityChanged?.cancel();
    _typingTimer?.cancel();
    horizontalScrollTimer.value?.cancel();
    _stickyTimer?.cancel();
    _bottomLoaderStartTimer?.cancel();
    _bottomLoaderEndTimer?.cancel();
    listController.removeListener(_listControllerListener);
    listController.sliverController.stickyIndex.removeListener(_updateSticky);
    listController.dispose();

    send.onClose();
    edit.value?.onClose();

    if (chat?.chat.value.isDialog == true) {
      chat?.members.values.lastWhereOrNull((u) => u.id != me)?.stopUpdates();
    }

    super.onClose();
  }

  // TODO: Handle [CallAlreadyExistsException].
  /// Starts a [ChatCall] in this [Chat] [withVideo] or without.
  Future<void> call(bool withVideo) =>
      _callService.call(id, withVideo: withVideo);

  /// Joins the call in the [Chat] identified by the [id].
  Future<void> joinCall() => _callService.join(id, withVideo: false);

  /// Drops the call in the [Chat] identified by the [id].
  Future<void> dropCall() => _callService.leave(id);

  /// Hides the specified [ChatItem] for the authenticated [MyUser].
  Future<void> hideChatItem(ChatItem item) async {
    try {
      await _chatService.hideChatItem(item);
    } on HideChatItemException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Deletes the specified [ChatItem] posted by the authenticated [MyUser].
  Future<void> deleteMessage(ChatItem item) async {
    try {
      await _chatService.deleteChatItem(item);
    } on DeleteChatMessageException catch (e) {
      MessagePopup.error(e);
    } on DeleteChatForwardException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Resends the specified [ChatItem].
  Future<void> resendItem(ChatItem item) async {
    if (item.status.value == SendingStatus.error) {
      await _chatService
          .resendChatItem(item)
          .then((_) =>
              AudioUtils.once(AudioSource.asset('audio/message_sent.mp3')))
          .onError<PostChatMessageException>((e, _) => MessagePopup.error(e))
          .onError<UploadAttachmentException>((e, _) => MessagePopup.error(e))
          .onError<ConnectionException>((_, __) {});
    }
  }

  /// Starts the editing of the specified [item], if allowed.
  void editMessage(ChatItem item) {
    if (!item.isEditable(chat!.chat.value, me!)) {
      MessagePopup.error('err_uneditable_message'.l10n);
      return;
    }

    if (item is ChatMessage) {
      edit.value ??= MessageFieldController(
        _chatService,
        _userService,
        text: item.text?.val,
        onSubmit: () async {
          final ChatMessage item = edit.value?.edited.value as ChatMessage;

          if (edit.value?.field.text == item.text?.val) {
            edit.value?.onClose();
            edit.value = null;
          } else if (edit.value!.field.text.isNotEmpty ||
              item.attachments.isNotEmpty) {
            ChatMessageText? text;
            if (edit.value!.field.text.isNotEmpty) {
              text = ChatMessageText(edit.value!.field.text);
            }

            try {
              await _chatService.editChatMessage(item, text);

              edit.value?.onClose();
              edit.value = null;

              _typingSubscription?.cancel();
              _typingSubscription = null;
              _typingTimer?.cancel();

              if (send.field.isEmpty.isFalse) {
                send.field.focus.requestFocus();
              }
            } on EditChatMessageException catch (e) {
              MessagePopup.error(e);
            } catch (e) {
              MessagePopup.error(e);
              rethrow;
            }
          }
        },
        onChanged: () {
          if (edit.value?.edited.value == null) {
            edit.value?.onClose();
            edit.value = null;
          }
        },
      );

      edit.value?.edited.value = item;
      edit.value?.field.focus.requestFocus();
    }
  }

  /// Updates [RxChat.draft] with the current values of the [send] field.
  void updateDraft() {
    // [Attachment]s to persist in a [RxChat.draft].
    final Iterable<MapEntry<GlobalKey, Attachment>> persisted;

    // Only persist uploaded [Attachment]s on Web to minimize byte writing lags.
    if (PlatformUtils.isWeb) {
      persisted = send.attachments.where(
        (e) => e.value is ImageAttachment || e.value is FileAttachment,
      );
    } else {
      persisted = List.from(send.attachments, growable: false);
    }

    chat?.setDraft(
      text: send.field.text.isEmpty ? null : ChatMessageText(send.field.text),
      attachments: persisted.map((e) => e.value).toList(),
      repliesTo: List.from(send.replied, growable: false),
    );
  }

  /// Fetches the local [chat] value from [_chatService] by the provided [id].
  Future<void> _fetchChat() async {
    _ignorePositionChanges = true;

    status.value = RxStatus.loading();
    chat = await _chatService.get(id);
    if (chat == null) {
      status.value = RxStatus.empty();
    } else {
      unreadMessages = chat!.chat.value.unreadCount;

      final ChatMessage? draft = chat!.draft.value;

      send.field.unchecked = draft?.text?.val ?? send.field.text;
      send.field.unsubmit();
      send.replied.value = List.from(
        draft?.repliesTo.map((e) => e.original).whereNotNull() ?? <ChatItem>[],
      );

      for (Attachment e in draft?.attachments ?? []) {
        send.attachments.add(MapEntry(GlobalKey(), e));
      }

      // Adds the provided [ChatItem] to the [elements].
      void add(Rx<ChatItem> e) {
        ChatItem item = e.value;

        // Put a [DateTimeElement] with [ChatItem.at] day, if not already.
        PreciseDateTime day = item.at.toDay();
        DateTimeElement dateElement = DateTimeElement(day);
        elements.putIfAbsent(dateElement.id, () => dateElement);

        if (item is ChatMessage) {
          ChatMessageElement element = ChatMessageElement(e);

          ListElement? previous = elements[elements.firstKeyAfter(element.id)];
          ListElement? next = elements[elements.lastKeyBefore(element.id)];

          bool insert = true;

          // Combine this [ChatMessage] with previous and next [ChatForward]s,
          // if it was posted less than [groupForwardThreshold] ago.
          if (previous is ChatForwardElement &&
              previous.authorId == item.author.id &&
              item.at.val
                      .difference(previous.forwards.last.value.at.val)
                      .abs() <
                  groupForwardThreshold &&
              previous.note.value == null) {
            insert = false;
            previous.note.value = e;
          } else if (next is ChatForwardElement &&
              next.authorId == item.author.id &&
              next.forwards.last.value.at.val.difference(item.at.val).abs() <
                  groupForwardThreshold &&
              next.note.value == null) {
            insert = false;
            next.note.value = e;
          }

          if (insert) {
            elements[element.id] = element;
          }
        } else if (item is ChatCall) {
          ChatCallElement element = ChatCallElement(e);
          elements[element.id] = element;
        } else if (item is ChatInfo) {
          ChatInfoElement element = ChatInfoElement(e);
          elements[element.id] = element;
        } else if (item is ChatForward) {
          ChatForwardElement element =
              ChatForwardElement(forwards: [e], e.value.at);

          ListElementId? previousKey = elements.firstKeyAfter(element.id);
          ListElement? previous = elements[previousKey];

          ListElementId? nextKey = elements.lastKeyBefore(element.id);
          ListElement? next = elements[nextKey];

          bool insert = true;

          if (previous is ChatForwardElement &&
              previous.authorId == item.author.id &&
              item.at.val
                      .difference(previous.forwards.last.value.at.val)
                      .abs() <
                  groupForwardThreshold) {
            // Add this [ChatForward] to previous [ChatForwardElement], if it
            // was posted less than [groupForwardThreshold] ago.
            previous.forwards.add(e);
            previous.forwards.sort((a, b) => a.value.at.compareTo(b.value.at));
            insert = false;
          } else if (previous is ChatMessageElement &&
              previous.item.value.author.id == item.author.id &&
              item.at.val.difference(previous.item.value.at.val).abs() <
                  groupForwardThreshold) {
            // Add the previous [ChatMessage] to this [ChatForwardElement.note],
            // if it was posted less than [groupForwardThreshold] ago.
            element.note.value = previous.item;
            elements.remove(previousKey);
          } else if (next is ChatForwardElement &&
              next.authorId == item.author.id &&
              next.forwards.first.value.at.val.difference(item.at.val).abs() <
                  groupForwardThreshold) {
            // Add this [ChatForward] to next [ChatForwardElement], if it was
            // posted less than [groupForwardThreshold] ago.
            next.forwards.add(e);
            next.forwards.sort((a, b) => a.value.at.compareTo(b.value.at));
            insert = false;
          } else if (next is ChatMessageElement &&
              next.item.value.author.id == item.author.id &&
              next.item.value.at.val.difference(item.at.val).abs() <
                  groupForwardThreshold) {
            // Add the next [ChatMessage] to this [ChatForwardElement.note], if
            // it was posted less than [groupForwardThreshold] ago.
            element.note.value = next.item;
            elements.remove(nextKey);
          }

          if (insert) {
            elements[element.id] = element;
          }
        }
      }

      for (Rx<ChatItem> e in chat!.messages) {
        add(e);
      }

      _messagesSubscription = chat!.messages.changes.listen((e) {
        switch (e.op) {
          case OperationKind.added:
            add(e.element);
            break;

          case OperationKind.removed:
            ChatItem item = e.element.value;

            ListElementId key = ListElementId(item.at, item.id);
            ListElement? element = elements[key];

            ListElementId? before = elements.firstKeyAfter(key);
            ListElement? beforeElement = elements[before];

            ListElementId? after = elements.lastKeyBefore(key);
            ListElement? afterElement = elements[after];

            // Remove the [DateTimeElement] before, if this [ChatItem] is the
            // last in this [DateTime] period.
            if (beforeElement is DateTimeElement &&
                (afterElement == null || afterElement is DateTimeElement) &&
                (element is! ChatForwardElement ||
                    (element.forwards.length == 1 &&
                        element.note.value == null))) {
              elements.remove(before);
            }

            // When removing [ChatMessage] or [ChatForward], the [before] and
            // [after] elements must be considered as well, since they may be
            // grouped in the same [ChatForwardElement].
            if (item is ChatMessage) {
              if (element is ChatMessageElement &&
                  item.id == element.item.value.id) {
                elements.remove(key);
              } else if (beforeElement is ChatForwardElement &&
                  beforeElement.note.value?.value.id == item.id) {
                beforeElement.note.value = null;
              } else if (afterElement is ChatForwardElement &&
                  afterElement.note.value?.value.id == item.id) {
                afterElement.note.value = null;
              } else if (element is ChatForwardElement &&
                  element.note.value?.value.id == item.id) {
                element.note.value = null;
              }
            } else if (item is ChatCall && element is ChatCallElement) {
              if (item.id == element.item.value.id) {
                elements.remove(key);
              }
            } else if (item is ChatInfo && element is ChatInfoElement) {
              if (item.id == element.item.value.id) {
                elements.remove(key);
              }
            } else if (item is ChatForward) {
              ChatForwardElement? forward;

              if (beforeElement is ChatForwardElement &&
                  beforeElement.forwards.any((e) => e.value.id == item.id)) {
                forward = beforeElement;
              } else if (afterElement is ChatForwardElement &&
                  afterElement.forwards.any((e) => e.value.id == item.id)) {
                forward = afterElement;
              } else if (element is ChatForwardElement &&
                  element.forwards.any((e) => e.value.id == item.id)) {
                forward = element;
              }

              if (forward != null) {
                forward.forwards.removeWhere((e) => e.value.id == item.id);

                if (forward.forwards.isEmpty) {
                  elements.remove(forward.id);

                  if (forward.note.value != null) {
                    ChatMessageElement message =
                        ChatMessageElement(forward.note.value!);
                    elements[message.id] = message;
                  }
                }
              }
            }
            break;

          case OperationKind.updated:
            // No-op.
            break;
        }
      });

      _chatWorker = ever(chat!.chat, (Chat e) {
        if (e.id != id) {
          WebUtils.replaceState(id.val, e.id.val);
          id = e.id;
        }
      });

      listController.sliverController.onPaintItemPositionsCallback =
          (height, positions) {
        if (positions.isNotEmpty) {
          _topVisibleItem = positions.last;

          _lastVisibleItem = positions.firstWhereOrNull((e) {
            ListElement element = elements.values.elementAt(e.index);
            return element is ChatMessageElement ||
                element is ChatInfoElement ||
                element is ChatCallElement ||
                element is ChatForwardElement;
          });

          if (_lastVisibleItem != null &&
              status.value.isSuccess &&
              !status.value.isLoadingMore) {
            ListElement element =
                elements.values.elementAt(_lastVisibleItem!.index);

            // If the [_lastVisibleItem] is posted after the [_lastSeenItem],
            // then set the [_lastSeenItem] to this item.
            if (!element.id.id.isLocal &&
                (_lastSeenItem.value == null ||
                    element.id.at.isAfter(_lastSeenItem.value!.at))) {
              if (element is ChatMessageElement) {
                _lastSeenItem.value = element.item.value;
              } else if (element is ChatInfoElement) {
                _lastSeenItem.value = element.item.value;
              } else if (element is ChatCallElement) {
                _lastSeenItem.value = element.item.value;
              } else if (element is ChatForwardElement) {
                _lastSeenItem.value = element.forwards.last.value;
              }
            }
          }
        }
      };

      if (chat?.chat.value.isDialog == true) {
        chat?.members.values
            .lastWhereOrNull((u) => u.id != me)
            ?.listenUpdates();
      }

      _readWorker ??= ever(_lastSeenItem, readChat);

      // If [RxChat.status] is not successful yet, populate the
      // [_messageInitializedWorker] to determine the initial messages list
      // index and offset.
      if (!chat!.status.value.isSuccess) {
        _messageInitializedWorker = ever(chat!.status, (RxStatus status) async {
          if (_messageInitializedWorker != null) {
            if (status.isSuccess) {
              _messageInitializedWorker?.dispose();
              _messageInitializedWorker = null;

              await Future.delayed(Duration.zero);

              if (!this.status.value.isSuccess) {
                this.status.value = RxStatus.loadingMore();
              }

              _determineLastRead();
              var result = _calculateListViewIndex();
              initIndex = result.index;
              initOffset = result.offset;
            }
          }
        });
      } else {
        _determineLastRead();
        var result = _calculateListViewIndex();
        initIndex = result.index;
        initOffset = result.offset;

        status.value = RxStatus.loadingMore();
      }

      _bottomLoaderStartTimer = Timer(
        const Duration(seconds: 2),
        () {
          if ((!status.value.isSuccess || status.value.isLoadingMore) &&
              elements.isNotEmpty) {
            _bottomLoader = LoaderElement.bottom(
              (chat?.messages.lastOrNull?.value.at
                      .add(const Duration(microseconds: 1)) ??
                  PreciseDateTime.now()),
            );

            elements[_bottomLoader!.id] = _bottomLoader!;
          }
        },
      );

      await chat!.around();

      // Required in order for [Hive.boxEvents] to add the messages.
      await Future.delayed(Duration.zero);

      Rx<ChatItem>? firstUnread = _firstUnread;
      _determineLastRead();

      // Scroll to the last read message if [_firstUnread] was updated or there
      // are no unread messages in [chat]. Otherwise,
      // [FlutterListViewDelegate.keepPosition] handles this as the last read
      // item is already in the list.
      if (firstUnread?.value.id != _firstUnread?.value.id ||
          chat!.chat.value.unreadCount == 0 && _bottomLoader == null) {
        _scrollToLastRead();
      }

      status.value = RxStatus.success();

      if (_bottomLoader != null) {
        showLoaders.value = false;

        _bottomLoaderEndTimer = Timer(const Duration(milliseconds: 300), () {
          if (_bottomLoader != null) {
            elements.remove(_bottomLoader!.id);
            _bottomLoader = null;
            showLoaders.value = true;
          }
        });
      }

      if (_lastSeenItem.value != null) {
        readChat(_lastSeenItem.value);
      }
    }

    _ensureScrollable();
    _ignorePositionChanges = false;
  }

  /// Returns an [User] from [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Marks the [chat] as read for the authenticated [MyUser] until the [item]
  /// inclusively.
  Future<void> readChat(ChatItem? item) async {
    if (active.isTrue &&
        item != null &&
        !chat!.chat.value.isReadBy(item, me) &&
        status.value.isSuccess &&
        !status.value.isLoadingMore &&
        item.status.value == SendingStatus.sent) {
      try {
        await _chatService.readChat(chat!.chat.value.id, item.id);
      } on ReadChatException catch (e) {
        MessagePopup.error(e);
      } on ConnectionException {
        // No-op.
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      }
    }
  }

  /// Animates [listController] to a [ChatItem] identified by the provided [id].
  Future<void> animateTo(
    ChatItemId id, {
    bool offsetBasedOnBottom = true,
    double offset = 50,
  }) async {
    int index = elements.values.toList().indexWhere((e) {
      return e.id.id == id ||
          (e is ChatForwardElement &&
              (e.forwards.any((e1) => e1.value.id == id) ||
                  e.note.value?.value.id == id));
    });

    if (index != -1) {
      _highlight(index);

      if (listController.hasClients) {
        await listController.sliverController.animateToIndex(
          index,
          offsetBasedOnBottom: offsetBasedOnBottom,
          offset: offset,
          duration: 200.milliseconds,
          curve: Curves.ease,
        );
      } else {
        initIndex = index;
      }
    }
  }

  /// Animates [listController] to the last [ChatItem] in the [RxChat.messages]
  /// list.
  Future<void> animateToBottom() async {
    if (chat?.messages.isEmpty == false && listController.hasClients) {
      canGoDown.value = false;

      _itemToReturnTo = _topVisibleItem;

      try {
        _ignorePositionChanges = true;
        await listController.sliverController.animateToIndex(
          0,
          offset: 0,
          offsetBasedOnBottom: false,
          duration: 300.milliseconds,
          curve: Curves.ease,
        );
        canGoBack.value = _itemToReturnTo != null;
      } finally {
        _ignorePositionChanges = false;
      }
    }
  }

  /// Animates [listController] to the [_itemToReturnTo].
  Future<void> animateToBack() async {
    if (_itemToReturnTo != null) {
      canGoBack.value = false;
      try {
        _ignorePositionChanges = true;

        if (listController.hasClients) {
          await listController.sliverController.animateToIndex(
            _itemToReturnTo!.index,
            offsetBasedOnBottom: true,
            offset: _itemToReturnTo!.offset,
            duration: 200.milliseconds,
            curve: Curves.ease,
          );
        } else {
          initIndex = _itemToReturnTo!.index;
        }
      } finally {
        _ignorePositionChanges = false;
        _listControllerListener();
      }
    }
  }

  /// Adds the specified [details] files to the [send] field.
  void dropFiles(DropDoneDetails details) async {
    for (var file in details.files) {
      send.addPlatformAttachment(PlatformFile(
        path: file.path,
        name: file.name,
        size: await file.length(),
        readStream: file.openRead(),
      ));
    }
  }

  /// Puts a [text] into the clipboard and shows a snackbar.
  void copyText(String text) {
    PlatformUtils.copy(text: text);
    MessagePopup.success('label_copied'.l10n, bottom: 76);
  }

  /// Returns a [List] of [GalleryAttachment]s representing a collection of all
  /// the media files of this [chat].
  List<GalleryAttachment> calculateGallery() {
    final List<GalleryAttachment> attachments = [];

    for (var m in chat?.messages ?? <Rx<ChatItem>>[]) {
      if (m.value is ChatMessage) {
        final ChatMessage msg = m.value as ChatMessage;
        attachments.addAll(
          msg.attachments
              .where(
                (e) =>
                    e is ImageAttachment || (e is FileAttachment && e.isVideo),
              )
              .map(
                (e) => GalleryAttachment(e, () => chat?.updateAttachments(msg)),
              ),
        );
      } else if (m.value is ChatForward) {
        final ChatForward msg = m.value as ChatForward;
        final ChatItemQuote item = msg.quote;

        if (item is ChatMessageQuote) {
          attachments.addAll(
            item.attachments
                .where(
                  (e) =>
                      e is ImageAttachment ||
                      (e is FileAttachment && e.isVideo),
                )
                .map(
                  (e) => GalleryAttachment(
                    e,
                    () => chat?.updateAttachments(m.value),
                  ),
                ),
          );
        }
      }
    }

    return attachments;
  }

  /// Keeps the [ChatService.keepTyping] subscription up indicating the ongoing
  /// typing in this [chat].
  void keepTyping() async {
    _typingSubscription ??= _chatService.keepTyping(id).listen((_) {});
    _typingTimer?.cancel();
    _typingTimer = Timer(_typingDuration, () {
      _typingSubscription?.cancel();
      _typingSubscription = null;
    });
  }

  /// Removes a [User] being a recipient of this [chat] from the blacklist.
  ///
  /// Only meaningful, if this [chat] is a dialog.
  Future<void> unblacklist() async {
    if (chat?.chat.value.isDialog == true) {
      final RxUser? recipient =
          chat!.members.values.firstWhereOrNull((e) => e.id != me);
      if (recipient != null) {
        await _userService.unblockUser(recipient.id);
      }
    }
  }

  /// Downloads the provided [FileAttachment], if not downloaded already, or
  /// otherwise opens it or cancels the download.
  Future<void> download(ChatItem item, FileAttachment attachment) async {
    if (attachment.isDownloading) {
      attachment.cancelDownload();
    } else if (await attachment.open() == false) {
      try {
        await attachment.download();
      } catch (e) {
        if (e is DioError && e.type == DioErrorType.cancel) {
          return;
        }

        await chat?.updateAttachments(item);
        await Future.delayed(Duration.zero);
        await attachment.download();
      }
    }
  }

  /// Highlights the item with the provided [index].
  Future<void> _highlight(int index) async {
    highlightIndex.value = index;

    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightTimeout, () {
      highlightIndex.value = null;
    });
  }

  /// Invokes [_updateSticky] and [_updateFabStates].
  ///
  /// Intended to be called as a listener of a [FlutterListViewController].
  void _listControllerListener() {
    if (listController.hasClients) {
      _updateSticky();
      _updateFabStates();
      _loadMessages();
    }
  }

  /// Updates the [canGoDown] and [canGoBack] indicators based on the
  /// [FlutterListViewController.position] value.
  void _updateFabStates() {
    if (listController.hasClients && !_ignorePositionChanges) {
      if (listController.position.pixels >
          MediaQuery.of(router.context!).size.height * 2 + 200) {
        canGoDown.value = true;
      } else {
        canGoDown.value = false;
      }

      if (canGoBack.isTrue) {
        canGoBack.value = false;
      }
    }
  }

  /// Updates the [showSticky] indicator and restarts a [_stickyTimer] resetting
  /// it.
  void _updateSticky() {
    showSticky.value = true;
    stickyIndex.value = listController.sliverController.stickyIndex.value;

    _stickyTimer?.cancel();
    _stickyTimer = Timer(const Duration(seconds: 2), () {
      if (stickyIndex.value != null) {
        final double? offset =
            listController.sliverController.getItemOffset(stickyIndex.value!);
        if (offset == null || offset == 0) {
          showSticky.value = false;
        } else {
          showSticky.value = (listController.offset +
                      MediaQuery.of(router.context!).size.height) -
                  offset >
              170;
        }
      }
    });
  }

  /// Ensures the [ChatView] is scrollable.
  Future<void> _ensureScrollable() async {
    await Future.delayed(1.milliseconds, () async {
      if (isClosed) {
        return;
      }

      if (!listController.hasClients) {
        return await _ensureScrollable();
      }

      // If the fetched initial page contains less elements than required to
      // fill the view and there's more pages available, then fetch those pages.
      if (listController.position.maxScrollExtent == 0 &&
          (hasNext.isTrue || hasPrevious.isTrue)) {
        await _loadNextPage();
        await _loadPreviousPage();
        _ensureScrollable();
      }
    });
  }

  /// Loads next and previous pages of the [RxChat.messages].
  void _loadMessages() async {
    if (!_ignorePositionChanges && status.value.isSuccess) {
      _loadNextPage();
      _loadPreviousPage();
    }
  }

  /// Loads next page of the [RxChat.messages], if [_atBottom].
  Future<void> _loadNextPage() async {
    if (hasNext.isTrue && chat!.nextLoading.isFalse && _atBottom) {
      keepPositionOffset.value = 0;

      if (_bottomLoader != null) {
        elements.remove(_bottomLoader!.id);
      }
      _bottomLoader =
          LoaderElement.bottom(elements.firstKey()?.at.add(1.milliseconds));
      elements[_bottomLoader!.id] = _bottomLoader!;

      await chat!.next();

      final double offset = listController.position.pixels;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (offset < loaderHeight) {
          listController.jumpTo(
            listController.position.pixels - (loaderHeight + 28),
          );
        }
        elements.remove(_bottomLoader?.id);
        _bottomLoader = null;

        keepPositionOffset.value = 20;
      });
    }
  }

  /// Loads previous page of the [RxChat.messages], if [_atTop].
  Future<void> _loadPreviousPage() async {
    if (hasPrevious.isTrue && chat!.previousLoading.isFalse && _atTop) {
      Log.print('Fetch previous page', 'ChatController');

      keepPositionOffset.value = 0;

      if (_topLoader == null) {
        _topLoader = LoaderElement.top();
        elements[_topLoader!.id] = _topLoader!;
      }

      elements[_topLoader!.id] = _topLoader!;

      await chat!.previous();

      if (hasPrevious.isFalse) {
        elements.remove(_topLoader?.id);
        _topLoader = null;
      }
    }
  }

  /// Determines the [_firstUnread] of the authenticated [MyUser] from the
  /// [RxChat.messages] list.
  void _determineLastRead() {
    if (chat?.unreadCount.value != 0) {
      _firstUnread = chat?.firstUnread;

      if (_firstUnread != null) {
        if (_unreadElement != null) {
          elements.remove(_unreadElement!.id);
        }

        PreciseDateTime? at =
            _firstUnread!.value.at.subtract(const Duration(microseconds: 1));
        _unreadElement = UnreadMessagesElement(at);
        elements[_unreadElement!.id] = _unreadElement!;
      }
    }
  }

  /// Calculates a [_ListViewIndexCalculationResult] of a [FlutterListView].
  _ListViewIndexCalculationResult _calculateListViewIndex([
    bool fixMotion = true,
  ]) {
    int index = 0;
    double offset = 0;

    if (itemId != null) {
      int i = elements.values.toList().indexWhere((e) => e.id.id == itemId);
      if (i != -1) {
        _highlight(i);
        index = i;
        offset = (MediaQuery.of(router.context!).size.height) / 3;
      }
    } else {
      if (chat?.messages.isEmpty == false) {
        if (chat!.chat.value.unreadCount == 0) {
          index = 0;
          offset = 0;
        } else if (_firstUnread != null) {
          int i = elements.values.toList().indexWhere((e) {
            if (e is ChatForwardElement) {
              if (e.note.value?.value.id == _firstUnread!.value.id) {
                return true;
              }

              return e.forwards.firstWhereOrNull(
                      (f) => f.value.id == _firstUnread!.value.id) !=
                  null;
            }

            return e.id.id == _firstUnread!.value.id;
          });
          if (i != -1) {
            index = i;
            offset = (MediaQuery.of(router.context!).size.height) / 3;
          }
        }
      }
    }

    if (fixMotion) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (listController.hasClients) {
          listController.jumpTo(
            listController.position.pixels >
                    listController.position.maxScrollExtent
                ? listController.position.maxScrollExtent
                : listController.position.pixels,
          );
        }
      });
    }

    return _ListViewIndexCalculationResult(index, offset);
  }

  /// Scrolls to the last read message.
  void _scrollToLastRead() {
    Future.delayed(1.milliseconds, () {
      if (listController.hasClients) {
        if (chat?.messages.isEmpty == false) {
          var result = _calculateListViewIndex(false);

          listController.jumpTo(
            listController.position.pixels >
                    listController.position.maxScrollExtent
                ? listController.position.maxScrollExtent
                : listController.position.pixels,
          );

          SchedulerBinding.instance.addPostFrameCallback((_) async {
            _ignorePositionChanges = true;
            await listController.sliverController.animateToIndex(
              result.index,
              offset: 0,
              offsetBasedOnBottom: false,
              duration: 200.milliseconds,
              curve: Curves.ease,
            );
            _ignorePositionChanges = false;
          });
        }
      } else {
        _scrollToLastRead();
      }
    });
  }
}

/// ID of a [ListElement] containing its [PreciseDateTime] and [ChatItemId].
class ListElementId implements Comparable<ListElementId> {
  const ListElementId(this.at, this.id);

  /// [PreciseDateTime] part of this [ListElementId].
  final PreciseDateTime at;

  /// [ChatItemId] part of this [ListElementId].
  final ChatItemId id;

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => '$at.$id';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListElementId &&
          runtimeType == other.runtimeType &&
          at == other.at &&
          id == other.id;

  @override
  int compareTo(ListElementId other) {
    final int result = at.compareTo(other.at);

    // `-` as [elements] are reversed.
    if (result == 0) {
      return -id.val.compareTo(other.id.val);
    }
    return -result;
  }
}

/// Element to display in a [FlutterListView].
abstract class ListElement {
  const ListElement(this.id);

  /// [ListElementId] of this [ListElement].
  final ListElementId id;
}

/// [ListElement] representing a [ChatMessage].
class ChatMessageElement extends ListElement {
  ChatMessageElement(this.item)
      : super(ListElementId(item.value.at, item.value.id));

  /// [ChatItem] of this [ChatMessageElement].
  final Rx<ChatItem> item;
}

/// [ListElement] representing a [ChatCall].
class ChatCallElement extends ListElement {
  ChatCallElement(this.item)
      : super(ListElementId(item.value.at, item.value.id));

  /// [ChatItem] of this [ChatCallElement].
  final Rx<ChatItem> item;
}

/// [ListElement] representing a [ChatInfo].
class ChatInfoElement extends ListElement {
  ChatInfoElement(this.item)
      : super(ListElementId(item.value.at, item.value.id));

  /// [ChatItem] of this [ChatInfoElement].
  final Rx<ChatItem> item;
}

/// [ListElement] representing a [ChatForward].
class ChatForwardElement extends ListElement {
  ChatForwardElement(
    PreciseDateTime at, {
    List<Rx<ChatItem>> forwards = const [],
    Rx<ChatItem>? note,
  })  : forwards = RxList(forwards),
        note = Rx(note),
        authorId = forwards.first.value.author.id,
        super(ListElementId(at, forwards.first.value.id));

  /// Forwarded [ChatItem]s.
  final RxList<Rx<ChatItem>> forwards;

  /// [ChatItem] attached to this [ChatForwardElement] as a note.
  final Rx<Rx<ChatItem>?> note;

  /// [UserId] being an author of the [forwards].
  final UserId authorId;
}

/// [ListElement] representing a [DateTime] label.
class DateTimeElement extends ListElement {
  DateTimeElement(PreciseDateTime at)
      : super(ListElementId(at, const ChatItemId('0')));
}

/// [ListElement] indicating unread [ChatItem]s below.
class UnreadMessagesElement extends ListElement {
  UnreadMessagesElement(PreciseDateTime at)
      : super(ListElementId(at, const ChatItemId('1')));
}

/// [ListElement] representing a [CustomProgressIndicator].
class LoaderElement extends ListElement {
  LoaderElement.bottom([PreciseDateTime? at])
      : super(
          ListElementId(
            at ?? PreciseDateTime.now().add(1.days),
            const ChatItemId('0'),
          ),
        );

  LoaderElement.top()
      : super(
          ListElementId(
            PreciseDateTime.fromMicrosecondsSinceEpoch(0),
            const ChatItemId('0'),
          ),
        );
}

/// Extension adding [ChatView] related wrappers and helpers.
extension ChatViewExt on Chat {
  /// Returns text represented title of this [Chat].
  String getTitle(Iterable<User> users, UserId? me) {
    String title = 'dot'.l10n * 3;

    switch (kind) {
      case ChatKind.monolog:
        title = name?.val ?? 'label_chat_monolog'.l10n;
        break;

      case ChatKind.dialog:
        User? partner = users.firstWhereOrNull((u) => u.id != me);
        final partnerName = partner?.name?.val ?? partner?.num.val;
        if (partnerName != null) {
          title = partnerName;
        }
        break;

      case ChatKind.group:
        if (name == null) {
          title = users
              .take(3)
              .map((u) => u.name?.val ?? u.num.val)
              .join('comma_space'.l10n);
          if (members.length > 3) {
            title += 'comma_space'.l10n + ('dot'.l10n * 3);
          }
        } else {
          title = name!.val;
        }
        break;

      case ChatKind.artemisUnknown:
        // No-op.
        break;
    }

    return title;
  }

  /// Returns string represented subtitle of this [Chat].
  ///
  /// If [isGroup], then returns the [members] length, otherwise returns the
  /// presence of the provided [partner], if any.
  String? getSubtitle({User? partner}) {
    switch (kind) {
      case ChatKind.dialog:
        return partner?.getStatus();

      case ChatKind.group:
        return '${members.length} ${'label_subtitle_participants'.l10n}';

      case ChatKind.monolog:
      case ChatKind.artemisUnknown:
        return null;
    }
  }

  /// Returns a string that is based on [members] or [id] of this [Chat].
  String colorDiscriminant(UserId? me) {
    switch (kind) {
      case ChatKind.monolog:
        return (members.firstOrNull?.user.num ?? id).val;
      case ChatKind.dialog:
        return (members.firstWhereOrNull((e) => e.user.id != me)?.user.num ??
                id)
            .val;
      case ChatKind.group:
      case ChatKind.artemisUnknown:
        return id.val;
    }
  }
}

/// Extension adding text representation of a [ChatCallFinishReason] value.
extension ChatCallFinishReasonL10n on ChatCallFinishReason {
  /// Returns text representation of a current value.
  String? localizedString([bool? fromMe]) {
    switch (this) {
      case ChatCallFinishReason.dropped:
        return fromMe == true
            ? 'label_chat_call_unanswered'.l10n
            : 'label_chat_call_missed'.l10n;
      case ChatCallFinishReason.declined:
        return 'label_chat_call_declined'.l10n;
      case ChatCallFinishReason.unanswered:
        return fromMe == true
            ? 'label_chat_call_unanswered'.l10n
            : 'label_chat_call_missed'.l10n;
      case ChatCallFinishReason.memberLeft:
        return 'label_chat_call_ended'.l10n;
      case ChatCallFinishReason.memberLostConnection:
        return 'label_chat_call_ended'.l10n;
      case ChatCallFinishReason.serverDecision:
        return 'label_chat_call_ended'.l10n;
      case ChatCallFinishReason.moved:
        return 'label_chat_call_moved'.l10n;
      case ChatCallFinishReason.artemisUnknown:
        return null;
    }
  }
}

/// Extension adding indication whether a [FileAttachment] represents a video.
extension FileAttachmentIsVideo on FileAttachment {
  /// Indicates whether this [FileAttachment] represents a video.
  bool get isVideo {
    String file = filename.toLowerCase();
    return file.endsWith('.mp4') ||
        file.endsWith('.mov') ||
        file.endsWith('.webm') ||
        file.endsWith('.mkv') ||
        file.endsWith('.flv') ||
        file.endsWith('.3gp');
  }
}

/// Extension adding an indicator whether a [ChatItem] is editable.
extension IsChatItemEditable on ChatItem {
  /// Indicates whether this [ChatItem] is editable.
  bool isEditable(Chat chat, UserId me) {
    if (author.id == me) {
      if (this is ChatMessage) {
        bool isRead = chat.isRead(this, me);
        return at
                .add(ChatController.editMessageTimeout)
                .isAfter(PreciseDateTime.now()) ||
            !isRead;
      }
    }

    return false;
  }
}

/// Extension adding conversion from [PreciseDateTime] to date-only
/// [PreciseDateTime].
extension _PreciseDateTimeToDayConversion on PreciseDateTime {
  /// Returns a [PreciseDateTime] containing only the date.
  ///
  /// For example, `2022-09-22 16:54:44.100` -> `2022-09-22 00:00:00.000`,
  PreciseDateTime toDay() {
    return PreciseDateTime(DateTime(val.year, val.month, val.day));
  }
}

/// Result of a [FlutterListView] initial index and offset calculation.
class _ListViewIndexCalculationResult {
  const _ListViewIndexCalculationResult(this.index, this.offset);

  /// Initial index of an item in the [FlutterListView].
  final int index;

  /// Initial [FlutterListView] offset.
  final double offset;
}

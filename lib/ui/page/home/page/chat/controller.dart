// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'dart:collection';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:mutex/mutex.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '/api/backend/schema.dart'
    hide
        ChatItemQuoteInput,
        ChatMessageTextInput,
        ChatMessageAttachmentsInput,
        ChatMessageRepliesInput;
import '/domain/model/application_settings.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_message_input.dart';
import '/domain/model/contact.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/model/welcome_message.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/settings.dart';
import '/domain/repository/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/notification.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show
        BlockUserException,
        ClearChatException,
        ConnectionException,
        DeleteChatForwardException,
        DeleteChatMessageException,
        EditChatMessageException,
        FavoriteChatException,
        HideChatException,
        HideChatItemException,
        JoinChatCallException,
        PostChatMessageException,
        ReadChatException,
        RemoveChatMemberException,
        ResubscriptionRequiredException,
        ToggleChatMuteException,
        UnblockUserException,
        UnfavoriteChatException,
        UploadAttachmentException;
import '/routes.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/widget/text_field.dart';
import '/ui/worker/cache.dart';
import '/util/audio_utils.dart';
import '/util/data_reader.dart';
import '/util/log.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import 'message_field/controller.dart';
import 'view.dart';

export 'view.dart';

/// Controller of the [Routes.chats] page.
class ChatController extends GetxController {
  ChatController(
    this.id,
    this._chatService,
    this._callService,
    this._authService,
    this._userService,
    this._settingsRepository,
    this._contactService,
    this._notificationService, {
    this.itemId,
    this.onContext,
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
  /// - `status.isLoadingMore`, meaning [chat] is already displayed and an
  ///   additional data is being fetched.
  Rx<RxStatus> status = Rx<RxStatus>(RxStatus.loading());

  /// [RxObsSplayTreeMap] of the [ListElement]s to display.
  final RxObsSplayTreeMap<ListElementId, ListElement> elements =
      RxObsSplayTreeMap();

  /// [MessageFieldController] for sending a [ChatMessage].
  late final MessageFieldController send;

  /// [MessageFieldController] for editing a [ChatMessage].
  final Rx<MessageFieldController?> edit = Rx(null);

  /// [TextFieldState] for blocking reason.
  final TextFieldState reason = TextFieldState();

  /// [SelectedContent] of a [SelectionArea] within this [ChatView].
  final Rx<SelectedContent?> selection = Rx(null);

  /// Interval of a [ChatMessage] since its creation within which this
  /// [ChatMessage] is allowed to be edited.
  static const Duration editMessageTimeout = Duration(minutes: 5);

  /// Bottom offset to apply to the last [ListElement] in the [elements].
  static const double lastItemBottomOffset = 10;

  /// [FlutterListViewController] of a messages [FlutterListView].
  final FlutterListViewController listController = FlutterListViewController();

  /// Summarized [Offset] of an ongoing scroll.
  Offset scrollOffset = Offset.zero;

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

  /// [ListElementId] of an item from the [elements] that should be highlighted.
  final Rx<ListElementId?> highlighted = Rx<ListElementId?>(null);

  /// [GlobalKey] of the more [ContextMenuRegion] button.
  final GlobalKey moreKey = GlobalKey();

  /// Indicator whether the [elements] selection mode is enabled.
  final RxBool selecting = RxBool(false);

  /// [ListElement]s selected during [selecting] mode.
  final RxList<ListElement> selected = RxList();

  /// Callback, called to retrieve the [BuildContext] that [ChatView] is built
  /// onto.
  final BuildContext Function()? onContext;

  /// Indicator whether any [ChatItemWidget] is being dragged right now.
  final RxBool isDraggingItem = RxBool(false);

  /// [TextFieldState] of the [ChatMessage]s searching.
  final TextFieldState search = TextFieldState();

  /// Reactive current query of the [search] field used for debouching.
  final RxnString query = RxnString();

  /// Indicator whether [search]ing is being active right now.
  final RxBool searching = RxBool(false);

  /// Subscription for [Paginated.updates] of the [search].
  StreamSubscription? _searchSubscription;

  /// [debounce] debouncing [query] to invoke searching.
  Worker? _searchDebounce;

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
  static const Duration _typingTimeout = Duration(seconds: 3);

  /// [StreamSubscription] to [ChatService.keepTyping] indicating an ongoing
  /// typing in this [chat].
  StreamSubscription? _typingSubscription;

  /// Subscription updating the [elements].
  StreamSubscription? _messagesSubscription;

  /// Subscription to the [PlatformUtilsImpl.onActivityChanged] updating the
  /// [active].
  StreamSubscription? _onActivityChanged;

  /// Subscription to the [PlatformUtilsImpl.onFocusChanged] invoking
  /// [_stopTyping].
  StreamSubscription? _onFocusChanged;

  /// Subscription for the [chat] changes.
  StreamSubscription? _chatSubscription;

  /// Subscription for the [RxUser] changes.
  StreamSubscription? _userSubscription;

  /// Indicator whether [_updateFabStates] should not be react on
  /// [FlutterListViewController.position] changes.
  bool _ignorePositionChanges = false;

  /// Currently displayed [UnreadMessagesElement] in the [elements] list.
  UnreadMessagesElement? _unreadElement;

  /// Currently displayed [LoaderElement] in the top of the [elements] list.
  LoaderElement? _topLoader;

  /// Currently displayed [LoaderElement] in the bottom of the [elements] list.
  LoaderElement? _bottomLoader;

  /// [Timer] canceling the [_typingSubscription] after [_typingTimeout].
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

  /// [ContactService] maintaining [ChatContact]s of this [me].
  final ContactService _contactService;

  /// Worker performing a [readChat] on [_lastSeenItem] changes.
  Worker? _readWorker;

  /// Worker performing a [readChat] when the [RouterState.obscuring] becomes
  /// empty.
  Worker? _obscuredWorker;

  /// Worker performing a jump to the last read message on a successful
  /// [RxChat.status].
  Worker? _messageInitializedWorker;

  /// Worker clearing [selected] on the [selected] changes.
  Worker? _selectingWorker;

  /// [Duration] of the highlighting.
  static const Duration _highlightTimeout = Duration(seconds: 1);

  /// [Timer] resetting the [highlighted] value after the [_highlightTimeout]
  /// has passed.
  Timer? _highlightTimer;

  /// [Timer] adding the [_bottomLoader] to the [elements] list.
  Timer? _bottomLoaderStartTimer;

  /// [Timer] deleting the [_bottomLoader] from the [elements] list.
  Timer? _bottomLoaderEndTimer;

  /// Indicator whether the [_loadMessages] is already invoked during the
  /// current frame.
  bool _messagesAreLoading = false;

  /// History of the [animateTo] transitions to [ChatItem]s to return back on
  /// the [animateToBottom] invokes.
  final List<ChatItem> _history = [];

  /// [Paginated] of [ChatItem]s to display in the [elements].
  Paginated<ChatItemId, Rx<ChatItem>>? _fragment;

  /// [Paginated]es used by this [ChatController].
  final HashSet<Paginated<ChatItemId, Rx<ChatItem>>> _fragments = HashSet();

  /// Subscriptions to the [Paginated.updates].
  final List<StreamSubscription> _fragmentSubscriptions = [];

  /// [Sentry] transaction monitoring this [ChatController] readiness.
  final ISentrySpan _ready = Sentry.startTransaction(
    'ui.chat.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
  );

  /// [Mutex] guarding access to [_typingSubscription].
  final Mutex _typingGuard = Mutex();

  /// [NotificationService] used for clearing notifications related to this
  /// [Chat].
  final NotificationService _notificationService;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Returns the [Uint8List] of the background.
  Rx<Uint8List?> get background => _settingsRepository.background;

  /// Returns the [ApplicationSettings].
  Rx<ApplicationSettings?> get settings =>
      _settingsRepository.applicationSettings;

  /// Indicates whether a previous page of the [elements] is exists.
  RxBool get hasPrevious => _fragment?.hasPrevious ?? chat!.hasPrevious;

  /// Indicates whether a next page of the [elements] is exists.
  RxBool get hasNext => _fragment?.hasNext ?? chat!.hasNext;

  /// Indicates whether a previous page of the [elements] is loading.
  RxBool get previousLoading =>
      _fragment?.previousLoading ?? chat!.previousLoading;

  /// Indicates whether a next page of the [elements] is loading.
  RxBool get nextLoading => _fragment?.nextLoading ?? chat!.nextLoading;

  /// Indicates whether the [chat] this [ChatController] is about is a dialog.
  bool get isDialog => chat?.chat.value.isDialog == true;

  /// Returns [RxUser] being recipient of this [chat].
  ///
  /// Only meaningful, if the [chat] is a dialog.
  RxUser? get user => isDialog
      ? chat?.members.values.firstWhereOrNull((e) => e.user.id != me)?.user
      : null;

  /// Returns the [WelcomeMessage] of this [chat], if any.
  WelcomeMessage? get welcomeMessage => user?.user.value.welcomeMessage;

  /// Returns [ChatId] of the [Chat]-monolog of the currently authenticated
  /// [MyUser], if any.
  ChatId get monolog => _chatService.monolog;

  /// Indicates whether the [listController] is scrolled to its bottom.
  bool get _atBottom =>
      listController.hasClients && listController.position.pixels < 500;

  /// Indicates whether the [listController] is scrolled to its top.
  bool get _atTop =>
      listController.hasClients &&
      listController.position.pixels >
          listController.position.maxScrollExtent - 500;

  /// Returns the [ChatContactId] of the [ChatContact] the [user] is linked to,
  /// if any.
  ChatContactId? get _contactId => user?.user.value.contacts.firstOrNull?.id;

  @override
  void onInit() {
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.add(_onBack, ifNotYetIntercepted: true);
    }

    send = MessageFieldController(
      _chatService,
      _userService,
      _settingsRepository,
      onChanged: updateDraft,
      onCall: call,
      onKeyUp: (key) {
        if (send.field.controller.text.isNotEmpty) {
          return false;
        }

        if (key == LogicalKeyboardKey.arrowUp) {
          final previous = chat?.messages.lastWhereOrNull((e) {
            return e.value is ChatMessage && !e.value.id.isLocal;
          });

          if (previous != null) {
            if (previous.value.isEditable(chat!.chat.value, me!)) {
              editMessage(previous.value);
              return true;
            }
          }
        }

        return false;
      },
      onSubmit: () async {
        _stopTyping();

        if (chat == null) {
          return;
        }

        if (send.field.text.trim().isNotEmpty ||
            send.attachments.isNotEmpty ||
            send.replied.isNotEmpty) {
          _chatService
              .sendChatMessage(
                chat?.chat.value.id ?? id,
                text: send.field.text.trim().isEmpty
                    ? null
                    : ChatMessageText(send.field.text.trim()),
                repliesTo: send.replied.map((e) => e.value).toList(),
                attachments: send.attachments.map((e) => e.value).toList(),
              )
              .then(
                (_) => AudioUtils.once(
                  AudioSource.asset('audio/message_sent.mp3'),
                ),
              )
              .onError<PostChatMessageException>(
                (_, _) => _showBlockedPopup(),
                test: (e) => e.code == PostChatMessageErrorCode.blocked,
              )
              .onError<UploadAttachmentException>(
                (e, _) => MessagePopup.error(e),
              )
              .onError<ConnectionException>((e, _) {});

          send.clear(unfocus: false);

          chat?.setDraft();
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

    _selectingWorker = ever(selecting, (bool value) {
      if (!value) {
        selected.clear();
      }
    });

    _onFocusChanged = PlatformUtils.onFocusChanged.listen((value) {
      if (!value) {
        _stopTyping();
      }
    });

    // Stop the [_typingSubscription] when the send field loses its focus.
    send.field.focus.addListener(_stopTypingOnUnfocus);

    search.focus.addListener(_disableSearchFocusListener);

    _searchDebounce = debounce(query, (String? query) async {
      status.value = RxStatus.loadingMore();

      if (query == null || query.isEmpty) {
        if (searching.value) {
          switchToMessages();
          status.value = RxStatus.success();
        }
      } else {
        _fragment = null;
        elements.clear();

        final Paginated<ChatItemId, Rx<ChatItem>>? fragment = await chat!
            .around(withText: ChatMessageText(query));

        _searchSubscription?.cancel();
        _searchSubscription = fragment!.updates.listen(
          null,
          onDone: () {
            _fragments.remove(fragment);
            _fragmentSubscriptions.remove(_searchSubscription?..cancel());

            // If currently used fragment is the one disposed, then switch to
            // the [RxChat.messages] for the [elements].
            if (_fragment == fragment) {
              switchToMessages();
            }
          },
        );

        _fragment = fragment;

        await _fragment!.around();

        elements.clear();
        _fragment!.items.values.forEach(_add);
        _subscribeFor(fragment: _fragment);
        _updateFabStates();

        status.value = RxStatus.success();
      }
    });

    HardwareKeyboard.instance.addHandler(_keyboardHandler);

    super.onInit();
  }

  @override
  void onReady() {
    listController.addListener(_listControllerListener);
    listController.sliverController.stickyIndex.addListener(_updateSticky);
    AudioUtils.ensureInitialized();
    _fetchChat();

    if (!PlatformUtils.isMobile) {
      send.field.focus.requestFocus();
    }

    super.onReady();
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    _readWorker?.dispose();
    _selectingWorker?.dispose();
    _obscuredWorker?.dispose();
    _typingSubscription?.cancel();
    _chatSubscription?.cancel();
    _userSubscription?.cancel();
    _onActivityChanged?.cancel();
    _onFocusChanged?.cancel();
    _typingTimer?.cancel();
    horizontalScrollTimer.value?.cancel();
    _stickyTimer?.cancel();
    _bottomLoaderStartTimer?.cancel();
    _bottomLoaderEndTimer?.cancel();
    listController.removeListener(_listControllerListener);
    listController.sliverController.stickyIndex.removeListener(_updateSticky);
    listController.dispose();
    _searchDebounce?.dispose();

    edit.value?.field.focus.removeListener(_stopTypingOnUnfocus);
    send.field.focus.removeListener(_stopTypingOnUnfocus);
    search.focus.removeListener(_disableSearchFocusListener);

    send.onClose();
    edit.value?.onClose();

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.remove(_onBack);
    }

    HardwareKeyboard.instance.removeHandler(_keyboardHandler);

    for (final s in _fragmentSubscriptions) {
      s.cancel();
    }

    super.onClose();
  }

  /// Starts a [ChatCall] in this [Chat] [withVideo] or without.
  Future<void> call(bool withVideo) async {
    try {
      await _callService.call(id, withVideo: withVideo);
    } on JoinChatCallException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Joins the call in the [Chat] identified by the [id].
  Future<void> joinCall() async {
    try {
      await _callService.join(id, withVideo: false);
    } on JoinChatCallException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Drops the call in the [Chat] identified by the [id].
  Future<void> dropCall() => _callService.leave(chat?.id ?? id);

  /// Hides the specified [ChatItem] for the authenticated [MyUser].
  Future<void> hideChatItem(ChatItem item) async {
    try {
      await _chatService.hideChatItem(item);
    } on HideChatItemException catch (e) {
      switch (e.code) {
        case HideChatItemErrorCode.unknownChatItem:
          // No-op.
          break;

        case HideChatItemErrorCode.artemisUnknown:
          MessagePopup.error('err_unknown'.l10n);
      }
    } on UnfavoriteChatException catch (e) {
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
      switch (e.code) {
        case DeleteChatMessageErrorCode.artemisUnknown:
          MessagePopup.error('err_data_transfer'.l10n);
          break;

        case DeleteChatMessageErrorCode.notAuthor:
        case DeleteChatMessageErrorCode.quoted:
        case DeleteChatMessageErrorCode.read:
          MessagePopup.error(e.toMessage());
          break;

        case DeleteChatMessageErrorCode.unknownChatItem:
          // No-op.
          break;
      }
    } on DeleteChatForwardException catch (e) {
      switch (e.code) {
        case DeleteChatForwardErrorCode.artemisUnknown:
          MessagePopup.error('err_data_transfer'.l10n);
          break;

        case DeleteChatForwardErrorCode.notAuthor:
        case DeleteChatForwardErrorCode.quoted:
        case DeleteChatForwardErrorCode.read:
          MessagePopup.error(e.toMessage());
          break;

        case DeleteChatForwardErrorCode.unknownChatItem:
          // No-op.
          break;
      }
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
          .then(
            (_) => AudioUtils.once(AudioSource.asset('audio/message_sent.mp3')),
          )
          .onError<PostChatMessageException>(
            (_, _) => _showBlockedPopup(),
            test: (e) => e.code == PostChatMessageErrorCode.blocked,
          )
          .onError<UploadAttachmentException>((e, _) => MessagePopup.error(e))
          .onError<ConnectionException>((_, _) {});
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
        _settingsRepository,
        text: item.text?.val,
        onKeyUp: (key) {
          if (key == LogicalKeyboardKey.escape) {
            final bool hasChanges =
                edit.value!.field.text != item.text?.val ||
                !const ListEquality().equals(
                  edit.value!.attachments.map((e) => e.value).toList(),
                  item.attachments,
                );

            if (hasChanges) {
              MessagePopup.alert(
                'label_discard_changes_question'.l10n,
                button: (context) => MessagePopup.deleteButton(
                  context,
                  label: 'btn_discard'.l10n,
                ),
              ).then((e) {
                if (e == true) {
                  closeEditing();
                }
              });
            } else {
              closeEditing();
            }

            return true;
          }

          return false;
        },
        onSubmit: () async {
          final ChatMessage item = edit.value?.edited.value as ChatMessage;

          _stopTyping();

          final bool hasText = edit.value!.field.text.trim().isNotEmpty;

          if (hasText ||
              edit.value!.attachments.isNotEmpty ||
              edit.value!.replied.isNotEmpty) {
            try {
              final ChatMessageTextInput text = ChatMessageTextInput(
                ChatMessageText(edit.value!.field.text),
              );

              final ChatMessageAttachmentsInput attachments =
                  ChatMessageAttachmentsInput(
                    edit.value!.attachments.map((e) => e.value).toList(),
                  );

              final ChatMessageRepliesInput repliesTo = ChatMessageRepliesInput(
                edit.value!.replied.map((e) => e.value.id).toList(),
              );

              closeEditing();

              send.field.focus.requestFocus();

              await _chatService.editChatMessage(
                item,
                text: text,
                attachments: attachments,
                repliesTo: repliesTo,
              );

              // If the message is not sent yet, resend it.
              if (item.status.value == SendingStatus.error) {
                await resendItem(item);
              }
            } on EditChatMessageException catch (e) {
              if (e.code == EditChatMessageErrorCode.blocked) {
                _showBlockedPopup();
              } else {
                MessagePopup.error(e);
              }
            } catch (e) {
              MessagePopup.error('err_data_transfer'.l10n);
              rethrow;
            }
          } else {
            closeEditing();
          }
        },
        onChanged: () {
          if (edit.value?.edited.value == null) {
            closeEditing();
          }
        },
      );

      edit.value?.edited.value = item;
      edit.value?.field.focus.requestFocus();

      // Stop the [_typingSubscription] when the edit field loses its focus.
      edit.value?.field.focus.addListener(_stopTypingOnUnfocus);
    }
  }

  /// Closes the [edit]ing if any.
  void closeEditing() {
    final bool hadFocus = edit.value?.field.focus.hasFocus == true;

    edit.value?.field.focus.removeListener(_stopTypingOnUnfocus);
    edit.value?.onClose();
    edit.value = null;

    if (!PlatformUtils.isMobile && hadFocus) {
      send.field.focus.requestFocus();
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
      repliesTo: List.from(send.replied.map((e) => e.value), growable: false),
    );
  }

  /// Fetches the local [chat] value from [_chatService] by the provided [id].
  Future<void> _fetchChat() async {
    ISentrySpan span = _ready.startChild('fetch');

    try {
      _ignorePositionChanges = true;

      status.value = RxStatus.loading();

      if (id.isLocal) {
        final UserId userId = id.userId;
        final FutureOr<RxUser?> userOrFuture = _userService.get(userId);
        final RxUser? user = userOrFuture is RxUser?
            ? userOrFuture
            : await userOrFuture;

        id = user?.user.value.dialog ?? id;
        if (user != null && user.id == me) {
          id = _chatService.monolog;
        }
      }

      final FutureOr<RxChat?> fetched = _chatService.get(id);
      chat = fetched is RxChat? ? fetched : await fetched;

      span.finish();
      span = _ready.startChild('fetch');

      if (chat == null) {
        status.value = RxStatus.empty();
      } else {
        _chatSubscription = chat!.updates.listen((_) {});

        unreadMessages = chat!.chat.value.unreadCount;

        await chat!.ensureDraft();
        final ChatMessage? draft = chat!.draft.value;

        if (send.field.text.isEmpty) {
          send.field.unchecked = draft?.text?.val ?? send.field.text;
        }

        send.field.unsubmit();
        send.replied.value = List.from(
          draft?.repliesTo.map((e) => e.original).nonNulls.map((e) => Rx(e)) ??
              <Rx<ChatItem>>[],
        );

        for (Attachment e in draft?.attachments ?? []) {
          send.attachments.add(MapEntry(GlobalKey(), e));
        }

        listController
            .sliverController
            .onPaintItemPositionsCallback = (height, positions) {
          if (positions.isNotEmpty) {
            _topVisibleItem = positions.last;

            _lastVisibleItem = positions.firstWhereOrNull((e) {
              ListElement? element = elements.values.elementAtOrNull(e.index);
              return element is ChatMessageElement ||
                  element is ChatInfoElement ||
                  element is ChatCallElement ||
                  element is ChatForwardElement;
            });

            if (_lastVisibleItem != null &&
                status.value.isSuccess &&
                !status.value.isLoadingMore) {
              final ListElement element = elements.values.elementAt(
                _lastVisibleItem!.index,
              );

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

        if (isDialog) {
          _userSubscription = chat?.members.values
              .lastWhereOrNull((u) => u.user.id != me)
              ?.user
              .updates
              .listen((_) {});
        }

        _readWorker ??= ever(_lastSeenItem, readChat);
        _obscuredWorker ??= ever(router.obscuring, (modals) {
          if (modals.isEmpty) {
            readChat(_lastSeenItem.value);
          }
        });

        _bottomLoaderStartTimer = Timer(const Duration(seconds: 2), () {
          if ((!status.value.isSuccess || status.value.isLoadingMore) &&
              elements.isNotEmpty) {
            _bottomLoader = LoaderElement.bottom(
              (chat?.messages.lastOrNull?.value.at.add(
                    const Duration(microseconds: 1),
                  ) ??
                  PreciseDateTime.now()),
            );

            elements[_bottomLoader!.id] = _bottomLoader!;
          }
        });

        // If [RxChat.status] is not successful yet, populate the
        // [_messageInitializedWorker] to determine the initial messages list
        // index and offset.
        if (!chat!.status.value.isSuccess) {
          _messageInitializedWorker = ever(chat!.status, (
            RxStatus status,
          ) async {
            if (_messageInitializedWorker != null) {
              if (status.isSuccess) {
                _messageInitializedWorker?.dispose();
                _messageInitializedWorker = null;

                await Future.delayed(Duration.zero);

                if (!this.status.value.isSuccess) {
                  this.status.value = RxStatus.loadingMore();
                }

                _determineFirstUnread();
                var result = _calculateListViewIndex();
                initIndex = result.index;
                initOffset = result.offset;

                Future.delayed(Duration(milliseconds: 500), _updateFabStates);
              }
            }
          });
        }

        span.finish();
        span = _ready.startChild('around');

        _ready.setTag('messages', '${chat!.messages.isNotEmpty}');
        _ready.setTag('local', '${id.isLocal}');

        if (itemId == null) {
          for (Rx<ChatItem> e in chat!.messages) {
            _add(e);
          }

          _subscribeFor(chat: chat);

          if (chat!.status.value.isSuccess) {
            _determineFirstUnread();
            final result = _calculateListViewIndex();
            initIndex = result.index;
            initOffset = result.offset;
            status.value = RxStatus.loadingMore();
          }

          await chat!.around();

          // Required in order for local storage to add the messages.
          await Future.delayed(Duration.zero);

          final Rx<ChatItem>? firstUnread = _firstUnread;
          _determineFirstUnread();

          // Scroll to the last read message if [_firstUnread] was updated.
          // Otherwise, [FlutterListViewDelegate.keepPosition] handles this as the
          // last read item is already in the list.
          if (firstUnread?.value.id != _firstUnread?.value.id) {
            _scrollToLastRead();
          }
        } else {
          await animateTo(itemId!);
        }

        span.finish();
        span = _ready.startChild('end');

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

      SchedulerBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: 500), _updateFabStates);
        _ensureScrollable();
      });

      _ignorePositionChanges = false;

      span.finish();

      SchedulerBinding.instance.addPostFrameCallback((_) => _ready.finish());

      // Clear notifications of the this `Chat` after it has finished loading.
      _notificationService.clearNotifications(chat?.chat.value.id ?? id);
    } catch (e) {
      _ready.throwable = e;
      _ready.finish(status: const SpanStatus.internalError());
      rethrow;
    }
  }

  /// Returns a reactive [User] from [UserService] by the provided [id].
  FutureOr<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Returns a reactive [ChatItem] by the provided [id].
  FutureOr<Rx<ChatItem>?> getItem(ChatItemId id) {
    Rx<ChatItem>? item;

    item = chat?.messages.firstWhereOrNull((e) => e.value.id == id);
    item ??= _fragments
        .firstWhereOrNull((e) => e.items.keys.contains(id))
        ?.items[id];

    if (item == null) {
      final Future<Rx<ChatItem>?>? future = chat?.single(id).then((
        fragment,
      ) async {
        if (fragment != null) {
          await fragment.around();
          _fragments.add(fragment);
          return fragment.items.values.firstOrNull;
        }

        return null;
      });

      return future;
    }

    return item;
  }

  /// Marks the [chat] as read for the authenticated [MyUser] until the [item]
  /// inclusively.
  Future<void> readChat(ChatItem? item) async {
    if (active.isTrue &&
        item != null &&
        !chat!.chat.value.isReadBy(item, me) &&
        status.value.isSuccess &&
        !status.value.isLoadingMore &&
        item.status.value == SendingStatus.sent &&
        router.obscuring.isEmpty) {
      try {
        await _chatService.readChat(chat!.chat.value.id, item.id);
      } on ReadChatException catch (_) {
        // No-op.
      } on ConnectionException {
        // No-op.
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Animates [listController] to a [ChatItem] identified by the provided
  /// [item] and its [reply] or [forward].
  Future<void> animateTo(
    ChatItemId itemId, {
    ChatItem? item,
    ChatItemQuote? reply,
    ChatItemQuote? forward,
    bool ignoreElements = false,
    bool offsetBasedOnBottom = true,
    bool addToHistory = true,
    double offset = 50,
  }) async {
    final ChatItem? original = reply?.original ?? forward?.original ?? item;
    final ChatItemId animateTo = original?.id ?? itemId;

    final int index = elements.values.toList().indexWhere((e) {
      return e.id.id == animateTo ||
          (e is ChatForwardElement &&
              (e.forwards.any((e1) => e1.value.id == animateTo) ||
                  e.note.value?.value.id == animateTo));
    });

    // If [original] is within the [elements], then just [animateToIndex].
    if (index != -1 && !ignoreElements) {
      _highlight(elements.values.elementAt(index).id);

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

      // And add the transition to the [history].
      if (addToHistory && item != null) {
        this.addToHistory(item);
      }

      _updateFabStates();
    } else {
      if (original != null) {
        final ListElementId elementId = ListElementId(original.at, original.id);
        final ListElementId? lastId = elements.values
            .lastWhereOrNull(
              (e) =>
                  e is ChatMessageElement ||
                  e is ChatInfoElement ||
                  e is ChatCallElement ||
                  e is ChatForwardElement,
            )
            ?.id;

        // If the [original] is placed before the first item, then animate to top,
        // or otherwise to bottom.
        if (lastId != null && elementId.compareTo(lastId) == 1) {
          if (_topLoader == null) {
            _topLoader = LoaderElement.top();
            elements[_topLoader!.id] = _topLoader!;
          }

          SchedulerBinding.instance.addPostFrameCallback((_) async {
            _ignorePositionChanges = true;
            await listController.sliverController.animateToIndex(
              elements.length - 1,
              offsetBasedOnBottom: true,
              offset: 0,
              duration: 300.milliseconds,
              curve: Curves.ease,
            );
            _ignorePositionChanges = false;

            _updateFabStates();
          });
        } else {
          if (_bottomLoader == null) {
            _bottomLoader = LoaderElement.bottom();
            elements[_bottomLoader!.id] = _bottomLoader!;
          }

          SchedulerBinding.instance.addPostFrameCallback((_) async {
            _ignorePositionChanges = true;
            await listController.sliverController.animateToIndex(
              0,
              offsetBasedOnBottom: true,
              offset: 0,
              duration: 300.milliseconds,
              curve: Curves.ease,
            );
            _ignorePositionChanges = false;

            _updateFabStates();
          });
        }
      }

      // And then try to fetch the items.
      try {
        await _fetchItemsAround(
          itemId,
          reply: reply?.original?.id,
          forward: forward?.original?.id,
        );

        final int index = elements.values.toList().indexWhere((e) {
          return e.id.id == animateTo ||
              (e is ChatForwardElement &&
                  (e.forwards.any((e1) => e1.value.id == animateTo) ||
                      e.note.value?.value.id == animateTo));
        });

        if (index != -1) {
          // [FlutterListView] ignores the [initIndex], if it is 0.
          if (index == 0) {
            initIndex = 1;
            initOffset = -5000;
          } else {
            initIndex = index;
            initOffset = offset;
          }

          _highlight(elements.values.elementAt(index).id);

          if (addToHistory && item != null) {
            this.addToHistory(item);
          }
        }
      } finally {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          // Stop the animation, if any.
          listController.jumpTo(listController.offset);

          // Ensure [FlutterListView] has correct index and offset.
          listController.sliverController.jumpToIndex(
            initIndex,
            offset: initOffset,
            offsetBasedOnBottom: offsetBasedOnBottom,
          );

          _ignorePositionChanges = false;

          elements.remove(_topLoader?.id);
          elements.remove(_bottomLoader?.id);
          _topLoader = null;
          _bottomLoader = null;

          _updateFabStates();
        });
      }
    }
  }

  /// Adds the provided [item] to the [_history].
  void addToHistory(ChatItem item) {
    _history.removeWhere((e) => e.key == item.key);
    _history.add(item);
    canGoDown.value = true;
  }

  /// Animates [listController] to the last [_history], if any, or the last
  /// [ChatItem] in the [RxChat.messages] otherwise.
  Future<void> animateToBottom() async {
    if (_history.isNotEmpty) {
      final ChatItem item = _history.removeLast();
      await animateTo(item.id, item: item, addToHistory: false);
      _updateFabStates();
    } else if (chat?.messages.isEmpty == false && listController.hasClients) {
      if (chat?.hasNext.value != false) {
        if (chat?.lastItem != null) {
          return animateTo(chat!.lastItem!.id, item: chat!.lastItem);
        }
      }

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

  /// Adds the specified [event] files to the [send] field.
  Future<void> dropFiles(PerformDropEvent event) async {
    for (final DropItem item in event.session.items) {
      item.dataReader?.asPlatformFile().then((e) {
        if (e != null) {
          send.addPlatformAttachment(e);
        }
      });
    }
  }

  /// Puts a [text] into the clipboard and shows a snackbar.
  void copyText(String text) {
    PlatformUtils.copy(text: text);
    MessagePopup.success('label_copied'.l10n, bottom: 76);
  }

  /// Returns a [Paginated] of [ChatItem]s containing a collection of all the
  /// media files of this [chat].
  Paginated<ChatItemId, Rx<ChatItem>> calculateGallery(ChatItem? item) {
    return chat!.attachments(item: item?.id);
  }

  /// Keeps [ChatService.keepTyping] subscription, if message field is not
  /// empty, or cancels it otherwise.
  void updateTyping() {
    final bool sendIsEmpty = send.field.text.isEmpty;
    final bool? editIsEmpty = edit.value?.field.text.isEmpty;

    if (editIsEmpty ?? sendIsEmpty) {
      _stopTyping();
    } else {
      _keepTyping();
    }
  }

  /// Removes [me] from the [chat].
  Future<void> leaveGroup() async {
    try {
      await _chatService.removeChatMember(id, me!);
      if (router.route.startsWith('${Routes.chats}/$id')) {
        router.home();
      }
    } on RemoveChatMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Hides the [chat].
  Future<void> hideChat() async {
    try {
      await _chatService.hideChat(id);
    } on HideChatException catch (e) {
      MessagePopup.error(e);
    } on UnfavoriteChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Mutes the [chat].
  Future<void> muteChat() async {
    try {
      await _chatService.toggleChatMute(chat?.id ?? id, MuteDuration.forever());
    } on ToggleChatMuteException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Unmutes the [chat].
  Future<void> unmuteChat() async {
    try {
      await _chatService.toggleChatMute(chat?.id ?? id, null);
    } on ToggleChatMuteException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Marks the [chat] as favorited.
  Future<void> favoriteChat() async {
    try {
      await _chatService.favoriteChat(chat?.id ?? id);
    } on FavoriteChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Removes the [chat] from the favorites.
  Future<void> unfavoriteChat() async {
    try {
      await _chatService.unfavoriteChat(chat?.id ?? id);
    } on UnfavoriteChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Adds the [user] to the contacts list of the authenticated [MyUser].
  ///
  /// Only meaningful, if this [chat] is a dialog.
  Future<void> addToContacts() async {
    if (_contactId == null) {
      try {
        await _contactService.createChatContact(user!.user.value);
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      }
    }
  }

  /// Removes the [user] from the contacts list of the authenticated [MyUser].
  ///
  /// Only meaningful, if this [chat] is a dialog.
  Future<void> removeFromContacts() async {
    try {
      final ChatContactId? contactId = _contactId;
      if (contactId != null) {
        await _contactService.deleteContact(contactId);
      }
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Clears all the [ChatItem]s of the [chat].
  Future<void> clearChat() async {
    try {
      await _chatService.clearChat(id);
    } on ClearChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Blocks the [user] for the authenticated [MyUser].
  ///
  /// Only meaningful, if this [chat] is a dialog.
  Future<void> block() async {
    try {
      if (user != null) {
        final String text = reason.text.trim();

        await _userService.blockUser(
          user!.id,
          text.isEmpty ? null : BlocklistReason(text),
        );
      }
      reason.clear();
    } on BlockUserException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Removes a [User] being a recipient of this [chat] from the blocklist.
  ///
  /// Only meaningful, if this [chat] is a dialog.
  Future<void> unblock() async {
    try {
      if (user != null) {
        await _userService.unblockUser(user!.id);
      }
    } on UnblockUserException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Downloads the provided [FileAttachment], if not downloaded already, or
  /// otherwise opens it or cancels the download.
  Future<void> downloadFile(ChatItem item, FileAttachment attachment) async {
    if (attachment.isDownloading) {
      attachment.cancelDownload();
    } else if (await attachment.open() == false) {
      try {
        await attachment.download();
      } catch (e) {
        if (e is DioException && e.type == DioExceptionType.cancel) {
          return;
        }

        await chat?.updateAttachments(item);
        await Future.delayed(Duration.zero);
        await attachment.download();
      }
    }
  }

  /// Downloads the provided image or video [attachments].
  Future<void> downloadMedia(List<Attachment> attachments, {String? to}) async {
    try {
      for (Attachment attachment in attachments) {
        if (attachment is! LocalAttachment) {
          await CacheWorker.instance
              .download(
                attachment.original.url,
                attachment.filename,
                attachment.original.size,
                checksum: attachment.original.checksum,
                to: attachments.length > 1 && to != null
                    ? '$to/${attachment.filename}'
                    : to,
              )
              .future;
        } else {
          // TODO: Implement [LocalAttachment] download.
          throw UnimplementedError();
        }
      }

      MessagePopup.success(
        attachments.length > 1
            ? 'label_files_downloaded'.l10n
            : attachments.first is ImageAttachment
            ? 'label_image_downloaded'.l10n
            : 'label_video_downloaded'.l10n,
      );
    } catch (e) {
      MessagePopup.error('err_could_not_download'.l10n);
      rethrow;
    }
  }

  /// Saves the provided [attachments] to the gallery.
  Future<void> saveToGallery(
    List<Attachment> attachments,
    ChatItem item,
  ) async {
    // Tries downloading the [attachments].
    Future<void> download() async {
      for (Attachment attachment in attachments) {
        if (attachment is! LocalAttachment) {
          if (attachment is FileAttachment && attachment.isVideo) {
            MessagePopup.success('label_video_downloading'.l10n);
          }
          try {
            await PlatformUtils.saveToGallery(
              attachment.original.url,
              attachment.filename,
              checksum: attachment.original.checksum,
              size: attachment.original.size,
              isImage: attachment is ImageAttachment,
            );
          } on UnsupportedError catch (_) {
            MessagePopup.error('err_unsupported_format'.l10n);
            continue;
          }
        } else {
          // TODO: Implement [LocalAttachment] download.
          throw UnimplementedError();
        }
      }

      MessagePopup.success(
        attachments.length > 1
            ? 'label_files_saved_to_gallery'.l10n
            : attachments.first is ImageAttachment
            ? 'label_image_saved_to_gallery'.l10n
            : 'label_video_saved_to_gallery'.l10n,
      );
    }

    try {
      try {
        await download();
      } on DioException catch (e) {
        if (e.response?.statusCode == 403) {
          await chat?.updateAttachments(item);
          await Future.delayed(Duration.zero);
          await download();
        } else {
          rethrow;
        }
      }
    } on UnsupportedError catch (_) {
      MessagePopup.error('err_unsupported_format'.l10n);
    } catch (_) {
      MessagePopup.error('err_could_not_download'.l10n);
      rethrow;
    }
  }

  /// Downloads the provided image or video [attachments] using `save as`
  /// dialog.
  Future<void> downloadMediaAs(List<Attachment> attachments) async {
    try {
      String? to = attachments.length > 1
          ? await FilePicker.platform.getDirectoryPath(lockParentWindow: true)
          : await FilePicker.platform.saveFile(
              fileName: attachments.first.filename,
              type: attachments.first is ImageAttachment
                  ? FileType.image
                  : FileType.video,
              lockParentWindow: true,
            );

      if (to != null) {
        await downloadMedia(attachments, to: to);
      }
    } catch (_) {
      MessagePopup.error('err_could_not_download'.l10n);
      rethrow;
    }
  }

  /// Enables or disabled [search]ing of the [ChatItem]s of this [Chat].
  void toggleSearch([bool? value]) {
    if (value ?? searching.value) {
      searching.value = false;
      search.clear();
      query.value = null;
      search.focus.removeListener(_disableSearchFocusListener);
      switchToMessages();
    } else {
      searching.value = true;
      search.focus.requestFocus();
      search.focus.addListener(_disableSearchFocusListener);
    }
  }

  /// Keeps the [ChatService.keepTyping] subscription up indicating the ongoing
  /// typing in this [chat].
  Future<void> _keepTyping() async {
    await _typingGuard.protect(() async {
      if (_typingSubscription == null) {
        Log.debug('_keepTyping()', '$runtimeType');

        final StackTrace invoked = StackTrace.current;

        _typingSubscription ??= _chatService
            .keepTyping(id)
            .timeout(
              Duration(minutes: 1),
              onTimeout: (_) async {
                Log.warning(
                  'Timeout of `keepTyping()` occurred with trace: $invoked',
                  '$runtimeType',
                );

                await Log.report(
                  TimeoutException('Timeout of `keepTyping()` occurred'),
                  trace: invoked,
                );
              },
            )
            .listen(
              (_) {},
              onError: (e) {
                if (e is ResubscriptionRequiredException) {
                  _stopTyping();
                  _keepTyping();
                } else {
                  throw e;
                }
              },
              cancelOnError: true,
            );
      }

      _typingTimer?.cancel();
      _typingTimer = Timer(_typingTimeout, _stopTyping);
    });
  }

  /// Stops the [ChatService.keepTyping] subscription indicating the typing has
  /// been stopped in this [chat].
  Future<void> _stopTyping() async {
    await _typingGuard.protect(() async {
      if (_typingSubscription != null) {
        Log.debug('_stopTyping()', '$runtimeType');
      }

      _typingTimer?.cancel();
      _typingSubscription?.cancel();
      _typingSubscription = null;
    });
  }

  /// Invokes the [_stopTyping], if [send] or [edit] fields lose its focus.
  Future<void> _stopTypingOnUnfocus() async {
    final bool sendHasFocus = send.field.focus.hasFocus;
    final bool editHasFocus = edit.value?.field.focus.hasFocus ?? false;
    if (!sendHasFocus && !editHasFocus) {
      await _stopTyping();
    }
  }

  // Uses the [chat] as [elements] source.
  void switchToMessages() {
    if (_fragment != null) {
      _fragment = null;
      elements.clear();
      _searchSubscription?.cancel();
      chat!.messages.forEach(_add);
      _subscribeFor(chat: chat);
    }
  }

  /// Fetches the [ChatItem]s around the provided [item] or its [reply] or
  /// [forward] and replaces the [elements] with them.
  Future<void> _fetchItemsAround(
    ChatItemId item, {
    ChatItemId? reply,
    ChatItemId? forward,
  }) async {
    final ChatItemId itemId = reply ?? forward ?? item;

    // If the [itemId] is within [RxChat.messages], then [switchToMessages].
    if (chat!.messages.any((e) => e.value.id == itemId)) {
      switchToMessages();
    } else {
      _fragment = _fragments.firstWhereOrNull(
        // Single-item fragments shouldn't be used to display messages in
        // pagination, as such fragments used only for [RxChat.single]s.
        (e) => e.items.keys.contains(itemId) && e.items.length > 1,
      );

      // If no fragments from the [_fragments] already contain the [itemId],
      // then fetch and use a new one from the [RxChat.around].
      if (_fragment == null) {
        final Paginated<ChatItemId, Rx<ChatItem>>? fragment = await chat!
            .around(item: item, reply: reply, forward: forward);

        StreamSubscription? subscription;
        subscription = fragment!.updates.listen(
          null,
          onDone: () {
            _fragments.remove(fragment);
            _fragmentSubscriptions.remove(subscription?..cancel());

            // If currently used fragment is the one disposed, then switch to
            // the [RxChat.messages] for the [elements].
            if (_fragment == fragment) {
              switchToMessages();
            }
          },
        );

        _fragments.add(fragment);
        _fragment = fragment;
      }

      await _fragment!.around();

      elements.clear();
      _fragment!.items.values.forEach(_add);
      _subscribeFor(fragment: _fragment);
    }
  }

  /// Adds the provided [ChatItem] to the [elements].
  void _add(Rx<ChatItem> e) {
    final ChatItem item = e.value;

    if (chat?.chat.value.unreadCount != 0) {
      final ListElementId elementId = ListElementId(item.at, item.id);
      final ListElement? previous = elements[elements.firstKeyAfter(elementId)];

      if (_unreadElement == null &&
          previous != null &&
          previous.id.id == chat?.chat.value.lastReadItem) {
        _unreadElement = UnreadMessagesElement(
          e.value.at.subtract(const Duration(microseconds: 1)),
        );
        elements[_unreadElement!.id] = _unreadElement!;
      }
    }

    // Put a [DateTimeElement] with [ChatItem.at] day, if not already.
    final PreciseDateTime day = item.at.toDay();
    final DateTimeElement dateElement = DateTimeElement(day);
    elements.putIfAbsent(dateElement.id, () => dateElement);

    if (item is ChatMessage) {
      final ChatMessageElement element = ChatMessageElement(e);

      final ListElement? previous =
          elements[elements.firstKeyAfter(element.id)];
      final ListElement? next = elements[elements.lastKeyBefore(element.id)];

      bool insert = true;

      // Combine this [ChatMessage] with previous and next [ChatForward]s, if it
      // was posted less than [groupForwardThreshold] ago.
      if (previous is ChatForwardElement &&
          previous.authorId == item.author.id &&
          item.at.val.difference(previous.forwards.last.value.at.val).abs() <
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
      final ChatCallElement element = ChatCallElement(e);
      elements[element.id] = element;
    } else if (item is ChatInfo) {
      final ChatInfoElement element = ChatInfoElement(e);
      elements[element.id] = element;
    } else if (item is ChatForward) {
      final ChatForwardElement element = ChatForwardElement(
        forwards: [e],
        e.value.at,
      );

      final ListElementId? previousKey = elements.firstKeyAfter(element.id);
      final ListElement? previous = elements[previousKey];

      final ListElementId? nextKey = elements.lastKeyBefore(element.id);
      final ListElement? next = elements[nextKey];

      bool insert = true;

      if (previous is ChatForwardElement &&
          previous.authorId == item.author.id &&
          item.at.val.difference(previous.forwards.last.value.at.val).abs() <
              groupForwardThreshold) {
        // Add this [ChatForward] to previous [ChatForwardElement], if it was
        // posted less than [groupForwardThreshold] ago.
        previous.forwards.add(e);
        previous.forwards.sort((a, b) => a.value.at.compareTo(b.value.at));
        insert = false;
      } else if (previous is ChatMessageElement &&
          previous.item.value.author.id == item.author.id &&
          item.at.val.difference(previous.item.value.at.val).abs() <
              groupForwardThreshold) {
        // Add the previous [ChatMessage] to this [ChatForwardElement.note], if
        // it was posted less than [groupForwardThreshold] ago.
        element.note.value = previous.item;
        elements.remove(previousKey);
      } else if (next is ChatForwardElement &&
          next.authorId == item.author.id &&
          next.forwards.first.value.at.val.difference(item.at.val).abs() <
              groupForwardThreshold) {
        // Add this [ChatForward] to next [ChatForwardElement], if it was posted
        // less than [groupForwardThreshold] ago.
        next.forwards.add(e);
        next.forwards.sort((a, b) => a.value.at.compareTo(b.value.at));
        insert = false;
      } else if (next is ChatMessageElement &&
          next.item.value.author.id == item.author.id &&
          next.item.value.at.val.difference(item.at.val).abs() <
              groupForwardThreshold) {
        // Add the next [ChatMessage] to this [ChatForwardElement.note], if it
        // was posted less than [groupForwardThreshold] ago.
        element.note.value = next.item;
        elements.remove(nextKey);
      }

      if (insert) {
        elements[element.id] = element;
      }
    }
  }

  /// Removes the provided [ChatItem] from the [elements].
  void _remove(ChatItem item) {
    final ListElementId key = ListElementId(item.at, item.id);
    final ListElement? element = elements[key];

    final ListElementId? before = elements.firstKeyAfter(key);
    final ListElement? beforeElement = elements[before];

    final ListElementId? after = elements.lastKeyBefore(key);
    final ListElement? afterElement = elements[after];

    // Remove the [DateTimeElement] before, if this [ChatItem] is the last in
    // this [DateTime] period.
    if (beforeElement is DateTimeElement &&
        (afterElement == null || afterElement is DateTimeElement) &&
        (element is! ChatForwardElement ||
            (element.forwards.length == 1 && element.note.value == null))) {
      elements.remove(before);
    }

    // When removing [ChatMessage] or [ChatForward], the [before] and [after]
    // elements must be considered as well, since they may be grouped in the
    // same [ChatForwardElement].
    if (item is ChatMessage) {
      if (element is ChatMessageElement && item.id == element.item.value.id) {
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
        if (forward.forwards.length == 1 &&
            forward.forwards.first.value.id == item.id) {
          elements.remove(forward.id);

          if (forward.note.value != null) {
            final ChatMessageElement message = ChatMessageElement(
              forward.note.value!,
            );
            elements[message.id] = message;
          }
        } else {
          forward.forwards.removeWhere((e) => e.value.id == item.id);
        }
      }
    }
  }

  /// Subscribes to the provided [chat] or [fragment] changes [_add]ing and
  /// [_remove]ing the [elements].
  void _subscribeFor({
    RxChat? chat,
    Paginated<ChatItemId, Rx<ChatItem>>? fragment,
  }) {
    _messagesSubscription?.cancel();

    if (chat != null) {
      _messagesSubscription = chat.messages.changes.listen((e) {
        switch (e.op) {
          case OperationKind.added:
          case OperationKind.updated:
            _add(e.element);
            break;

          case OperationKind.removed:
            _remove(e.element.value);
            _ensureScrollable();
            break;
        }
      });
    } else if (fragment != null) {
      _messagesSubscription = fragment.items.changes.listen((e) {
        switch (e.op) {
          case OperationKind.added:
          case OperationKind.updated:
            _add(e.value!);
            break;

          case OperationKind.removed:
            _remove(e.value!.value);
            _ensureScrollable();
            break;
        }
      });
    }
  }

  /// Highlights the item with the provided [id].
  Future<void> _highlight(ListElementId id) async {
    highlighted.value = id;

    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightTimeout, () {
      highlighted.value = null;
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
      // If we've reached the end of [elements], and there's no more down there,
      // then clear the history.
      if (listController.position.pixels == 0 && hasNext.isFalse) {
        _history.clear();
      }

      bool isHighEnough = false;

      final BuildContext? context = onContext?.call() ?? router.context;
      if (context != null) {
        isHighEnough =
            listController.position.pixels >
            MediaQuery.of(context).size.height * 2 + 200;
      }

      if (_history.isNotEmpty || isHighEnough) {
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
      if (isClosed) {
        return;
      }

      if (stickyIndex.value != null) {
        final double? offset = listController.sliverController.getItemOffset(
          stickyIndex.value!,
        );
        if (offset == null || offset == 0) {
          showSticky.value = false;
        } else {
          showSticky.value =
              (listController.offset +
                      MediaQuery.of(
                        onContext?.call() ?? router.context!,
                      ).size.height) -
                  offset >
              170;
        }
      }
    });
  }

  /// Ensures the [ChatView] is scrollable.
  Future<void> _ensureScrollable() async {
    if (isClosed) {
      return;
    }

    if (hasNext.isTrue || hasPrevious.isTrue) {
      await Future.delayed(1.milliseconds, () async {
        if (isClosed) {
          return;
        }

        if (!listController.hasClients) {
          return await _ensureScrollable();
        }

        // If the fetched initial page contains less elements than required to
        // fill the view and there's more pages available, then fetch those pages.
        if (listController.position.maxScrollExtent < 50) {
          await _loadNextPage();
          await _loadPreviousPage();
          _ensureScrollable();
        } else if (_atBottom) {
          await _loadNextPage();
        } else if (_atTop) {
          await _loadPreviousPage();
        }
      });
    }
  }

  /// Loads next and previous pages of the [RxChat.messages].
  void _loadMessages() async {
    if (!_messagesAreLoading) {
      _messagesAreLoading = true;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (isClosed) {
          return;
        }

        _messagesAreLoading = false;

        if (!_ignorePositionChanges && status.value.isSuccess) {
          _loadNextPage();
          _loadPreviousPage();
        }
      });
    }
  }

  /// Loads next page of the [RxChat.messages], if [_atBottom].
  Future<void> _loadNextPage() async {
    if (hasNext.isTrue && nextLoading.isFalse && _atBottom) {
      keepPositionOffset.value = 0;

      if (_bottomLoader != null) {
        elements.remove(_bottomLoader!.id);
      }
      _bottomLoader = LoaderElement.bottom(
        elements.firstKey()?.at.add(1.milliseconds),
      );
      elements[_bottomLoader!.id] = _bottomLoader!;

      await (_fragment?.next ?? chat!.next).call();

      double? offset;
      if (listController.hasClients) {
        offset = listController.position.pixels;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (listController.hasClients &&
            offset != null &&
            offset < loaderHeight) {
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
    if (hasPrevious.isTrue && previousLoading.isFalse && _atTop) {
      Log.info('Fetch previous page', 'ChatController');

      if (_topLoader == null) {
        _topLoader = LoaderElement.top();
        elements[_topLoader!.id] = _topLoader!;
      }

      await (_fragment?.previous ?? chat!.previous).call();

      if (hasPrevious.isFalse) {
        elements.remove(_topLoader?.id);
        _topLoader = null;
      }
    }
  }

  /// Determines the [_firstUnread] of the authenticated [MyUser] from the
  /// [RxChat.messages] list.
  void _determineFirstUnread() {
    if (chat?.unreadCount.value != 0) {
      _firstUnread = chat?.firstUnread;
    }
  }

  /// Calculates a [_ListViewIndexCalculationResult] of a [FlutterListView].
  _ListViewIndexCalculationResult _calculateListViewIndex([
    bool fixMotion = true,
  ]) {
    int index = 0;
    double offset = 0;

    if (chat?.messages.isEmpty == false) {
      if (chat!.chat.value.unreadCount == 0) {
        index = 0;
        offset = 0;
      } else if (_firstUnread != null) {
        final int i = elements.values.toList().indexWhere((e) {
          if (e is ChatForwardElement) {
            if (e.note.value?.value.id == _firstUnread!.value.id) {
              return true;
            }

            return e.forwards.firstWhereOrNull(
                  (f) => f.value.id == _firstUnread!.value.id,
                ) !=
                null;
          }

          return e.id.id == _firstUnread!.value.id;
        });

        if (i != -1) {
          index = i;

          try {
            offset =
                (MediaQuery.of(
                  onContext?.call() ?? router.context!,
                ).size.height) /
                3;
          } catch (_) {
            offset = 0;
          }
        }
      }
    }

    if (fixMotion) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (listController.hasClients &&
            listController.position.hasContentDimensions) {
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

          if (listController.position.hasContentDimensions) {
            listController.jumpTo(
              listController.position.pixels >
                      listController.position.maxScrollExtent
                  ? listController.position.maxScrollExtent
                  : listController.position.pixels,
            );
          }

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

  /// Invokes [closeEditing], if [edit]ing.
  ///
  /// Intended to be used as a [BackButtonInterceptor] callback, thus returns
  /// `true`, if back button should be intercepted, or otherwise returns
  /// `false`.
  bool _onBack(bool _, RouteInfo _) {
    if (edit.value != null) {
      closeEditing();
      return true;
    }

    return false;
  }

  /// Displays a [MessagePopup.error] visually representing a blocked error.
  ///
  /// Meant to be invoked in case of `blocked` type of errors possibly thrown
  /// during operations with this [Chat].
  void _showBlockedPopup() {
    switch (chat?.chat.value.kind) {
      case ChatKind.dialog:
        if (user != null) {
          MessagePopup.error(
            'err_blocked_by'.l10nfmt({
              'user': '${user?.user.value.name ?? user?.user.value.num}',
            }),
          );
        }
        break;

      case ChatKind.group:
        MessagePopup.error('err_blocked'.l10n);
        break;

      case ChatKind.monolog:
      case ChatKind.artemisUnknown:
      case null:
        // No-op.
        break;
    }
  }

  /// Disables the [search], if its focus is lost or its query is empty.
  void _disableSearchFocusListener() {
    if (search.focus.hasFocus == false && search.text.isEmpty == true) {
      toggleSearch(true);
    }
  }

  /// Enables or disables search based on the [event].
  bool _keyboardHandler(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyF:
          final Set<PhysicalKeyboardKey> pressed =
              HardwareKeyboard.instance.physicalKeysPressed;

          final bool isMetaPressed = pressed.any(
            (key) =>
                key == PhysicalKeyboardKey.metaLeft ||
                key == PhysicalKeyboardKey.metaRight,
          );

          final bool isControlPressed = pressed.any(
            (key) =>
                key == PhysicalKeyboardKey.controlLeft ||
                key == PhysicalKeyboardKey.controlRight,
          );

          if (isMetaPressed || isControlPressed) {
            toggleSearch();
            return true;
          }
          break;

        case LogicalKeyboardKey.escape:
          toggleSearch(true);
          return true;

        default:
          // No-op.
          break;
      }
    }

    return false;
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
  ListElement(this.id);

  /// [ListElementId] of this [ListElement].
  final ListElementId id;

  /// [GlobalKey] of the element to prevent it from rebuilding.
  final GlobalKey key = GlobalKey();
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
  }) : forwards = RxList(forwards),
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
  /// Returns string represented subtitle of this [Chat].
  ///
  /// If [isGroup], then returns the [members] length, otherwise returns the
  /// presence of the provided [partner], if any.
  String? getSubtitle({RxUser? partner}) {
    switch (kind) {
      case ChatKind.dialog:
        return partner?.user.value.getStatus(partner.lastSeen.value);

      case ChatKind.group:
        return 'label_subtitle_participants'.l10nfmt({'count': membersCount});

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

/// Extension adding [RxChat] related wrappers and helpers.
extension ChatRxExt on RxChat {
  /// Returns text represented title of this [RxChat].
  ///
  /// If [withDeletedLabel] is `true`, then returns the title with the deleted
  /// label for deleted users.
  String title({bool withDeletedLabel = true}) {
    String title = 'dot'.l10n * 3;

    switch (chat.value.kind) {
      case ChatKind.monolog:
        title = chat.value.name?.val ?? 'label_chat_monolog'.l10n;
        break;

      case ChatKind.dialog:
        final String? name =
            members.values
                .firstWhereOrNull((u) => u.user.id != me)
                ?.user
                .title(withDeletedLabel: withDeletedLabel) ??
            chat.value.members
                .firstWhereOrNull((e) => e.user.id != me)
                ?.user
                .title(withDeletedLabel: withDeletedLabel);

        title = name ?? title;
        break;

      case ChatKind.group:
        if (chat.value.name != null) {
          title = chat.value.name!.val;
        } else {
          final Iterable<String> names;

          final List<RxUser> users = members.values
              .take(3)
              .map((e) => e.user)
              .toList();

          if (users.length < chat.value.membersCount && users.length < 3) {
            names = chat.value.members
                .take(3)
                .map((e) => e.user.title(withDeletedLabel: withDeletedLabel));
          } else {
            names = users
                .take(3)
                .map((e) => e.title(withDeletedLabel: withDeletedLabel));
          }

          title = names.join('comma_space'.l10n);
          if (chat.value.membersCount > 3) {
            title += 'comma_space'.l10n + ('dot'.l10n * 3);
          }
        }
        break;

      case ChatKind.artemisUnknown:
        // No-op.
        break;
    }

    return title;
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
        return 'label_chat_call_ended'.l10n;
      case ChatCallFinishReason.artemisUnknown:
        return null;
    }
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

/// Extension adding conversion on [ListElement]s to [ChatItem]s.
extension SelectedToItemsExtension on RxList<ListElement> {
  /// Returns the [ChatItem]s this list of [ListElement] represents.
  List<ChatItem> get asItems {
    final List<ChatItem> items = [];

    for (var e in this) {
      if (e is ChatMessageElement) {
        items.add(e.item.value);
      } else if (e is ChatCallElement) {
        items.add(e.item.value);
      } else if (e is ChatInfoElement) {
        items.add(e.item.value);
      } else if (e is ChatForwardElement) {
        if (e.note.value != null) {
          items.add(e.note.value!.value);
        }

        for (var f in e.forwards) {
          items.add(f.value);
        }
      }
    }

    return items;
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

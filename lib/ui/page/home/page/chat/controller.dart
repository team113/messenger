// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'dart:math';

import 'package:back_button_interceptor/back_button_interceptor.dart';
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
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/domain/service/balance.dart';
import 'package:messenger/domain/service/my_user.dart';

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
import '/domain/model/chat_item_quote_input.dart';
import '/domain/model/chat_message_input.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart'
    show
        CallAlreadyExistsException,
        CallAlreadyJoinedException,
        CallDoesNotExistException,
        CallIsInPopupException;
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/settings.dart';
import '/domain/repository/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
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
        ToggleChatMuteException,
        UnblockUserException,
        UnfavoriteChatException,
        UploadAttachmentException;
import '/routes.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/widget/text_field.dart';
import '/ui/worker/cache.dart';
import '/util/audio_utils.dart';
import '/util/log.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'insufficient_funds/view.dart';
import 'forward/view.dart';
import 'message_field/controller.dart';
import 'view.dart';
import 'widget/chat_gallery.dart';

export 'view.dart';

enum ConfirmAction {
  audioCall,
  videoCall,
  sendMessage,
}

/// Controller of the [Routes.chats] page.
class ChatController extends GetxController {
  ChatController(
    this.id,
    this._chatService,
    this._callService,
    this._authService,
    this._userService,
    this._myUserService,
    this._settingsRepository,
    this._contactService,
    this._balanceService, {
    this.itemId,
    this.welcome,
  });

  /// ID of this [Chat].
  ChatId id;

  /// [RxChat] of this page.
  RxChat? chat;

  /// ID of the [ChatItem] to scroll to initially in this [ChatView].
  final ChatItemId? itemId;

  // TODO: Remove when backend supports it out of the box.
  /// [ChatMessageText] serving as a welcome message to display in this [Chat].
  final ChatMessageText? welcome;

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

  /// Summarized [Offset] of an ongoing scroll.
  Offset scrollOffset = Offset.zero;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

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

  /// [GlobalKey] of the more [ContextMenuRegion] button.
  final GlobalKey moreKey = GlobalKey();

  /// Indicator whether the [user] has a [ChatContact] associated with them in
  /// the address book of the authenticated [MyUser].
  final RxBool inContacts = RxBool(false);

  /// Indicator whether the [elements] selection mode is enabled.
  final RxBool selecting = RxBool(false);

  // final RxList<ChatItemId> visible = RxList();
  final RxMap<ChatItemId, double> visible = RxMap();

  final RxBool emailNotValidated = RxBool(false);

  final RxBool joinWall = RxBool(false);

  bool paid = false;

  final RxBool acceptPaid = RxBool(false);
  final Rx<Alignment> paidAlignment = Rx(Alignment.topCenter);

  final RxBool paidDisclaimer = RxBool(false);
  final RxBool paidDisclaimerDismissed = RxBool(false);
  final RxBool paidBorder = RxBool(false);
  final RxBool paidAccepted = RxBool(false);

  ConfirmAction? confirmAction;

  final RxBool hoveredPinned = RxBool(false);
  final RxBool allowPinnedHiding = RxBool(false);
  final RxList<ChatItem> pinned = RxList();
  final RxInt displayPinned = RxInt(0);

  /// [ListElement]s selected during [selecting] mode.
  final RxList<ListElement> selected = RxList();

  void pin(ChatItem item) {
    pinned.add(item);
    displayPinned.value = pinned.length - 1;
  }

  void unpin([int? index]) {
    pinned.removeAt(index ?? displayPinned.value);

    if (pinned.isEmpty) {
      hoveredPinned.value = false;
    } else {
      displayPinned.value = min(displayPinned.value, pinned.length - 1);
    }

    // allowPinnedHiding.value = false;
  }

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

  /// Subscription for the [chat] changes.
  StreamSubscription? _chatSubscription;

  /// [StreamSubscription] to [ContactService.contacts] determining the
  /// [inContacts] indicator.
  StreamSubscription? _contactsSubscription;

  /// Indicator whether [_updateFabStates] should not be react on
  /// [FlutterListViewController.position] changes.
  bool _ignorePositionChanges = false;

  bool get ignorePositionChanges => _ignorePositionChanges;

  /// Index of an item from the [elements] that should be highlighted.
  final RxnInt highlight = RxnInt(null);

  /// Height of a [LoaderElement] displayed in the message list.
  static const double loadingHeight = 64;

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

  final MyUserService _myUserService;

  /// [AbstractSettingsRepository], used to get the [background] value.
  final AbstractSettingsRepository _settingsRepository;

  final BalanceService _balanceService;

  /// [ContactService] maintaining [ChatContact]s of this [me].
  final ContactService _contactService;

  /// [TextFieldState] for blacklisting reason.
  final TextFieldState reason = TextFieldState();

  /// Worker performing a [readChat] on [lastVisible] changes.
  Worker? _readWorker;

  /// Worker performing a jump to the last read message on a successful
  /// [RxChat.status].
  Worker? _messageInitializedWorker;

  /// Worker capturing any [RxChat.chat] changes.
  Worker? _chatWorker;

  /// Worker clearing [selected] on the [selected] changes.
  Worker? _selectingWorker;

  /// [Duration] of the highlighting.
  static const Duration _highlightTimeout = Duration(seconds: 1);

  /// [Timer] resetting the [highlightIndex] value after the [_highlightTimeout]
  /// has passed.
  Timer? _highlightTimer;

  /// [Timer] adding the [_bottomLoader] to the [elements] list.
  Timer? _bottomLoaderStartTimer;

  /// [Timer] deleting the [_bottomLoader] from the [elements] list.
  Timer? _bottomLoaderEndTimer;

  /// Indicator whether the [_loadMessages] is already invoked during the
  /// current frame.
  bool _messagesAreLoading = false;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Returns the [Uint8List] of the background.
  Rx<Uint8List?> get background => _settingsRepository.background;

  /// Returns the [ApplicationSettings].
  Rx<ApplicationSettings?> get settings =>
      _settingsRepository.applicationSettings;

  /// Indicates whether a previous page of the [elements] is exists.
  RxBool get hasPrevious => chat!.hasPrevious;

  /// Indicates whether a next page of the [elements] is exists.
  RxBool get hasNext => chat!.hasNext;

  /// Returns the [CallButtonsPosition] currently set.
  CallButtonsPosition? get callPosition => settings.value?.callButtonsPosition;

  /// Returns [RxUser] being recipient of this [chat].
  ///
  /// Only meaningful, if the [chat] is a dialog.
  RxUser? get user => chat?.chat.value.isDialog == true
      ? chat?.members.values.firstWhereOrNull((e) => e.id != me)
      : null;

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
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.add(_onBack, ifNotYetIntercepted: true);
    }

    send = MessageFieldController(
      _chatService,
      _userService,
      _myUserService,
      _settingsRepository,
      onChanged: updateDraft,
      onCall: call,
      onSubmit: ({bool onlyDonation = false}) async {
        if (paidAccepted.value) {
          paidDisclaimerDismissed.value = true;
          paidDisclaimer.value = false;
          paidBorder.value = false;
        }

        if (emailNotValidated.value) {
          paidBorder.value = true;
          paidAlignment.value = Alignment.bottomCenter;
          return;
        }

        if (paid && !paidDisclaimerDismissed.value) {
          if (paidDisclaimer.value) {
            paidBorder.value = true;
            paidAlignment.value = Alignment.bottomCenter;
          }

          paidDisclaimer.value = true;
          confirmAction = ConfirmAction.sendMessage;
          return;
        }

        if (paid && send.donation.value == null) {
          if (_balanceService.balance.value < 100) {
            InsufficientFundsView.show(
              router.context!,
              description: 'label_message_cant_send_message_funds'.l10n,
            );
            return;
          } else {
            _balanceService.add(
              OutgoingTransaction(amount: -100, at: DateTime.now()),
            );
          }
        }

        if (send.donation.value != null) {
          if (_balanceService.balance.value < send.donation.value!) {
            InsufficientFundsView.show(
              router.context!,
              description: 'label_gift_cant_send_message_funds'.l10n,
            );
            return;
          } else {
            _balanceService.add(
              OutgoingTransaction(
                amount: -send.donation.value!.toDouble(),
                at: DateTime.now(),
              ),
            );
          }
        }

        if (send.forwarding.value) {
          if (send.replied.isNotEmpty) {
            if (send.replied.any((e) => e is ChatCall)) {
              MessagePopup.error('err_cant_forward_calls'.l10n);
              return;
            }

            await ChatForwardView.show(
              router.context!,
              id,
              send.replied.map((e) => ChatItemQuoteInput(item: e)).toList(),
              text: send.field.text,
              attachments: send.attachments.map((e) => e.value).toList(),
              onSent: send.clear,
            );
          }
        } else {
          String text = onlyDonation ? '' : send.field.text.trim();
          if (send.donation.value != null) {
            text += '?donate=${send.donation.value}';
          }

          if (text.isNotEmpty ||
              send.attachments.isNotEmpty ||
              send.replied.isNotEmpty) {
            _chatService
                .sendChatMessage(
                  chat?.chat.value.id ?? id,
                  text: text.isEmpty ? null : ChatMessageText(text),
                  repliesTo: onlyDonation ? [] : send.replied.reversed.toList(),
                  attachments: onlyDonation
                      ? []
                      : send.attachments.map((e) => e.value).toList(),
                )
                .then((_) => AudioUtils.once(
                    AudioSource.asset('audio/message_sent.mp3')))
                .onError<PostChatMessageException>(
                    (e, _) => MessagePopup.error(e))
                .onError<UploadAttachmentException>(
                    (e, _) => MessagePopup.error(e))
                .onError<ConnectionException>((e, _) {});

            if (onlyDonation) {
              send.donation.value = null;
            } else {
              send.clear();
            }

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

    send.hasCall.value = chat?.inCall.value ?? false;

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
    _selectingWorker?.dispose();
    _typingSubscription?.cancel();
    _chatSubscription?.cancel();
    _contactsSubscription?.cancel();
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

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.remove(_onBack);
    }

    super.onClose();
  }

  // TODO: Handle [CallAlreadyExistsException].
  /// Starts a [ChatCall] in this [Chat] [withVideo] or without.
  Future<void> call(bool withVideo) async {
    if (paidAccepted.value) {
      paidDisclaimerDismissed.value = true;
      paidDisclaimer.value = false;
      paidBorder.value = false;
    }

    if (paid && !paidDisclaimerDismissed.value) {
      if (paidDisclaimer.value) {
        paidBorder.value = true;
        paidAlignment.value = Alignment.topCenter;
      }

      paidDisclaimer.value = true;
      confirmAction =
          withVideo ? ConfirmAction.videoCall : ConfirmAction.audioCall;
      return;
    }

    if (paid) {
      if (_balanceService.balance.value < 100) {
        await InsufficientFundsView.show(
          router.context!,
          description: 'label_message_cant_make_call_funds'.l10n,
        );
        return;
      } else {
        _balanceService.add(
          OutgoingTransaction(amount: -100, at: DateTime.now()),
        );
      }
    }

    await _callService.call(id, withVideo: withVideo);
  }

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

  Future<void> rejectChatItem(ChatItem item) async {
    if (item.author.isDeleted) {
      await MessagePopup.alert(
        'Ошибка',
        description: [
          TextSpan(
            text:
                'К сожалению, возрат средств невозможен. Аккаунт пользователя ${item.author.name ?? item.author.num} удалён.',
          ),
        ],
      );
      return;
    }

    final sum = item is ChatMessage ? (item.donate ?? 123) : 123;

    if (_balanceService.balance.value < sum.toDouble()) {
      await InsufficientFundsView.show(
        router.context!,
        description: 'label_donate_cant_reject_donate'.l10n,
      );
    } else {
      // TODO
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
        _myUserService,
        _settingsRepository,
        text: item.text?.val,
        onSubmit: ({bool onlyDonation = false}) async {
          final ChatMessage item = edit.value?.edited.value as ChatMessage;

          if (edit.value!.field.text.trim().isNotEmpty ||
              edit.value!.attachments.isNotEmpty ||
              edit.value!.replied.isNotEmpty) {
            try {
              await _chatService.editChatMessage(
                item,
                text: ChatMessageTextInput(
                  ChatMessageText(edit.value!.field.text),
                ),
                attachments: ChatMessageAttachmentsInput(
                  edit.value!.attachments.map((e) => e.value).toList(),
                ),
                repliesTo: ChatMessageRepliesInput(
                  edit.value!.replied.map((e) => e.id).toList(),
                ),
              );

              closeEditing();

              if (send.field.isEmpty.isFalse) {
                send.field.focus.requestFocus();
              }
            } on EditChatMessageException catch (e) {
              MessagePopup.error(e);
            } catch (e) {
              MessagePopup.error(e);
              rethrow;
            }
          } else {
            MessagePopup.error('err_no_text_no_attachment_and_reply'.l10n);
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
    }
  }

  /// Closes the [edit]ing if any.
  void closeEditing() {
    edit.value?.onClose();
    edit.value = null;
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

  FeeElement? feeElement;

  /// Fetches the local [chat] value from [_chatService] by the provided [id].
  Future<void> _fetchChat() async {
    _ignorePositionChanges = true;

    status.value = RxStatus.loading();

    final FutureOr<RxChat?> fetched = _chatService.get(id);
    chat = fetched is RxChat? ? fetched : await fetched;

    if (chat == null) {
      status.value = RxStatus.empty();
    } else {
      joinWall.value =
          chat?.chat.value.isGroup == true && router.joinByLink != null;
      send.hasCall.value = chat!.inCall.value;

      _chatSubscription = chat!.updates.listen((_) {});

      unreadMessages = chat!.chat.value.unreadCount;

      final ChatMessage? draft = chat!.draft.value;

      if (send.field.text.isEmpty) {
        send.field.unchecked = draft?.text?.val ?? send.field.text;
      }

      send.inCall = chat!.inCall;
      send.field.unsubmit();
      send.replied.value = List.from(
        draft?.repliesTo.map((e) => e.original).whereNotNull() ?? <ChatItem>[],
      );

      for (Attachment e in draft?.attachments ?? []) {
        send.attachments.add(MapEntry(GlobalKey(), e));
      }

      paid = chat!.members.values.any((e) =>
              e.user.value.name?.val.toLowerCase() == 'alex1' ||
              e.user.value.name?.val.toLowerCase() == 'alex2' ||
              e.user.value.name?.val.toLowerCase() == 'kirey') &&
          chat!.chat.value.isDialog;
      paidDisclaimer.value = paid;
      refresh();

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
                if (forward.forwards.length == 1 &&
                    forward.forwards.first.value.id == item.id) {
                  elements.remove(forward.id);

                  if (forward.note.value != null) {
                    ChatMessageElement message =
                        ChatMessageElement(forward.note.value!);
                    elements[message.id] = message;
                  }
                } else {
                  forward.forwards.removeWhere((e) => e.value.id == item.id);
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

        send.hasCall.value = e.ongoingCall != null;
      });

      listController.sliverController.onPaintItemPositionsCallback =
          (height, positions) {
        if (positions.isNotEmpty) {
          _topVisibleItem = positions.last;

          final Map<ChatItemId, double> items = {};

          for (var e in positions) {
            final ListElement? element =
                elements.values.elementAtOrNull(e.index);

            if (element is ChatMessageElement) {
              items[element.id.id] = e.offset;
            } else if (element is ChatCallElement) {
              items[element.id.id] = e.offset;
            } else if (element is ChatInfoElement) {
              items[element.id.id] = e.offset;
            } else if (element is ChatForwardElement) {
              items[element.id.id] = e.offset;
            }
          }

          visible.value = items;

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

              _determineFirstUnread();
              var result = _calculateListViewIndex();
              initIndex = result.index;
              initOffset = result.offset;
            }
          }
        });
      } else {
        _determineFirstUnread();
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
      _determineFirstUnread();

      // Scroll to the last read message if [_firstUnread] was updated or there
      // are no unread messages in [chat]. Otherwise,
      // [FlutterListViewDelegate.keepPosition] handles this as the last read
      // item is already in the list.
      if (firstUnread?.value.id != _firstUnread?.value.id ||
          chat!.chat.value.unreadCount == 0 && _bottomLoader == null) {
        _scrollToLastRead();
      }

      if (welcome != null) {
        chat!.addMessage(welcome!);
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

      if (chat?.chat.value.isDialog == true) {
        inContacts.value = _contactService.contacts.values.any(
          (e) => e.contact.value.users.every((m) => m.id == user?.id),
        );

        _contactsSubscription = _contactService.contacts.changes.listen((e) {
          switch (e.op) {
            case OperationKind.added:
            case OperationKind.updated:
              if (e.value!.contact.value.users.isNotEmpty &&
                  e.value!.contact.value.users.any((e) => e.id == user?.id)) {
                inContacts.value = true;
              }
              break;

            case OperationKind.removed:
              if (e.value?.contact.value.users.any((e) => e.id == user?.id) ==
                  true) {
                inContacts.value = false;
              }
              break;
          }
        });
      }
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _ensureScrollable();
    });

    _ignorePositionChanges = false;
  }

  /// Returns an [User] from [UserService] by the provided [id].
  FutureOr<RxUser?> getUser(UserId id) => _userService.get(id);

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
        _ignorePositionChanges = true;
        await listController.sliverController.animateToIndex(
          index,
          offsetBasedOnBottom: offsetBasedOnBottom,
          offset: offset,
          duration: 200.milliseconds,
          curve: Curves.ease,
        );
        _ignorePositionChanges = false;
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
    if (!inContacts.value) {
      try {
        await _contactService.createChatContact(user!.user.value);
        inContacts.value = true;
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
    if (inContacts.value) {
      try {
        final RxChatContact? contact =
            _contactService.contacts.values.firstWhereOrNull(
          (e) => e.contact.value.users.every((m) => m.id == user?.id),
        );
        await _contactService.deleteContact(contact!.contact.value.id);
        inContacts.value = false;
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      }
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
        await _userService.blockUser(
          user!.id,
          reason.text.isEmpty ? null : BlocklistReason(reason.text),
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
      if (isClosed) {
        return;
      }

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
    if (hasNext.isTrue && chat!.nextLoading.isFalse && _atBottom) {
      keepPositionOffset.value = 0;

      if (_bottomLoader != null) {
        elements.remove(_bottomLoader!.id);
      }
      _bottomLoader =
          LoaderElement.bottom(elements.firstKey()?.at.add(1.milliseconds));
      elements[_bottomLoader!.id] = _bottomLoader!;

      await chat!.next();

      double? offset;
      if (listController.hasClients) {
        offset = listController.position.pixels;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (offset != null && offset < loaderHeight) {
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
      Log.info('Fetch previous page', 'ChatController');

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
  void _determineFirstUnread() {
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

  /// Invokes [closeEditing], if [edit]ing.
  ///
  /// Intended to be used as a [BackButtonInterceptor] callback, thus returns
  /// `true`, if back button should be intercepted, or otherwise returns
  /// `false`.
  bool _onBack(bool _, RouteInfo __) {
    if (edit.value != null) {
      closeEditing();
      return true;
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

class PaidElement extends ListElement {
  PaidElement(this.messages, this.calls)
      : super(
          ListElementId(
            PreciseDateTime(DateTime.now().add(const Duration(days: 365))),
            const ChatItemId('2'),
          ),
        );

  final double messages;
  final double calls;
}

class FeeElement extends ListElement {
  FeeElement(this.fromMe)
      : super(ListElementId(PreciseDateTime.now(), ChatItemId('$fromMe')));

  final bool fromMe;
}

class InfoElement extends ListElement {
  InfoElement()
      : super(ListElementId(PreciseDateTime.now(), const ChatItemId('0')));
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
        final partnerName = partner?.name?.val ?? partner?.num.toString();
        if (partnerName != null) {
          title = partnerName;
        }
        break;

      case ChatKind.group:
        if (name == null) {
          title = users
              .take(3)
              .map((u) => u.name?.val ?? u.num.toString())
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
  String? getSubtitle({RxUser? partner}) {
    switch (kind) {
      case ChatKind.dialog:
        return partner?.user.value.getStatus(partner.lastSeen.value);

      case ChatKind.group:
        return 'label_subtitle_participants'.l10nfmt({'count': members.length});
      // return '${members.length} ${'label_subtitle_participants'.l10n}';

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
extension PreciseDateTimeToDayConversion on PreciseDateTime {
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

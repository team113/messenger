// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '/api/backend/schema.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
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
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

export 'view.dart';

/// Controller of the [Routes.chat] page.
class ChatController extends GetxController {
  ChatController(
    this.id,
    this._chatService,
    this._callService,
    this._authService,
    this._userService, {
    this.itemId,
  });

  /// ID of this [Chat].
  final ChatId id;

  /// [RxChat] of this page.
  RxChat? chat;

  /// ID of a [ChatItem] to scroll to initially in this [ChatView].
  final ChatItemId? itemId;

  /// Indicator whether the down FAB should be visible.
  final RxBool canGoDown = RxBool(false);

  /// Indicator whether the return FAB should be visible.
  final RxBool canGoBack = RxBool(false);

  /// Most recent recipient's [ChatItem] that was visible on the screen.
  final Rx<ChatItem?> lastVisibleItem = Rx<ChatItem?>(null);

  /// Last [ChatItem] read by the authenticated [MyUser] in this [Chat].
  final Rx<Rx<ChatItem>?> lastReadItem = Rx<Rx<ChatItem>?>(null);

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

  /// State of a send message field.
  late final TextFieldState send;

  /// [ChatItem] being quoted to reply onto.
  final Rx<ChatItem?> repliedMessage = Rx<ChatItem?>(null);

  /// State of an edit message field.
  TextFieldState? edit;

  /// [ChatItem] being edited.
  final Rx<ChatItem?> editedMessage = Rx<ChatItem?>(null);

  /// Interval of a [ChatMessage] since its creation within which this
  /// [ChatMessage] is allowed to be edited.
  static const Duration editMessageTimeout = Duration(minutes: 5);

  /// [FlutterListViewController] of a messages [FlutterListView].
  final FlutterListViewController listController = FlutterListViewController();

  /// Attachments to be attached to a message.
  RxList<Attachment> attachments = RxList<Attachment>();

  /// Indicator whether there is an ongoing drag-n-drop at the moment.
  final RxBool isDraggingFiles = RxBool(false);

  /// [Timer] for discarding any vertical movement in a [SingleChildScrollView]
  /// of [ChatItem]s when non-`null`.
  ///
  /// Indicates currently ongoing horizontal scroll of a view.
  final Rx<Timer?> horizontalScrollTimer = Rx(null);

  /// Maximum allowed [NativeFile.size] of an [Attachment].
  static const int maxAttachmentSize = 15 * 1024 * 1024;

  /// Top visible [FlutterListViewItemPosition] in the [FlutterListView].
  FlutterListViewItemPosition? _topVisibleItem;

  /// [ChatItem] to return to when the return FAB is pressed.
  ChatItem? _itemToReturnTo;

  /// Position offset to set when returning to the [_itemToReturnTo].
  double _offsetToReturnTo = 0;

  /// [Duration] considered as a timeout of the ongoing typing.
  static const Duration _typingDuration = Duration(seconds: 5);

  /// [StreamSubscription] to [ChatService.keepTyping] indicating an ongoing
  /// typing in this [chat].
  StreamSubscription? _typingSubscription;

  /// Indicator whether [_updateFabStates] should not be react on
  /// [FlutterListViewController.position] changes.
  bool _ignorePositionChanges = false;

  /// [Timer] canceling the [_typingSubscription] after [_typingDuration].
  Timer? _typingTimer;

  /// [AudioPlayer] playing a sent message sound.
  AudioPlayer? _audioPlayer;

  /// Call service used to start the call in this [Chat].
  final CallService _callService;

  /// [Chat]s service used to get [chat] value.
  final ChatService _chatService;

  /// [AuthService] used to get [me] value.
  final AuthService _authService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// Worker capturing any [RxChat.messages] changes.
  Worker? _messagesWorker;

  /// Worker performing a [readChat] on [lastVisible] changes.
  Worker? _readWorker;

  /// Worker performing a jump to the last read message on a successful
  /// [RxChat.status].
  Worker? _messageInitializedWorker;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Indicates whether the [listController] is at the bottom of a
  /// [FlutterListView].
  bool get atBottom {
    if (listController.hasClients) {
      return listController.position.pixels + 200 >=
          listController.position.maxScrollExtent;
    } else {
      return false;
    }
  }

  @override
  void onInit() {
    send = TextFieldState(
      onChanged: (s) => s.error.value = null,
      onSubmitted: (s) {
        if (s.text.isNotEmpty ||
            attachments.isNotEmpty ||
            repliedMessage.value != null) {
          _chatService
              .sendChatMessage(
                chat!.chat.value.id,
                text: s.text.isEmpty ? null : ChatMessageText(s.text),
                repliesTo: repliedMessage.value,
                attachments: attachments,
              )
              .then((_) => _playMessageSent())
              .onError<PostChatMessageException>(
                  (e, _) => MessagePopup.error(e))
              .onError<UploadAttachmentException>(
                  (e, _) => MessagePopup.error(e))
              .onError<ConnectionException>((e, _) {});

          repliedMessage.value = null;
          attachments.clear();
          s.clear();
          s.unsubmit();

          _typingSubscription?.cancel();
          _typingSubscription = null;
          _typingTimer?.cancel();

          if (!PlatformUtils.isMobile) {
            Future.delayed(Duration.zero, () => s.focus.requestFocus());
          }
        }
      },
    );

    super.onInit();
  }

  @override
  void onReady() {
    listController.addListener(_updateFabStates);
    _fetchChat();
    _initAudio();
    super.onReady();
  }

  @override
  void onClose() {
    _messagesWorker?.dispose();
    _readWorker?.dispose();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    horizontalScrollTimer.value?.cancel();
    listController.removeListener(_updateFabStates);
    listController.dispose();

    _audioPlayer?.dispose();
    [AudioCache.instance.loadedFiles['audio/message_sent.mp3']]
        .whereNotNull()
        .forEach(AudioCache.instance.clear);

    super.onClose();
  }

  // TODO: Handle [CallAlreadyExistsException].
  /// Starts a [ChatCall] in this [Chat] [withVideo] or without.
  Future<void> call(bool withVideo) =>
      _callService.call(id, withVideo: withVideo);

  /// Joins the call in the [Chat] identified by the [id].
  Future<void> joinCall() => _callService.join(id, withVideo: false);

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
          .then((_) => _playMessageSent())
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
      editedMessage.value = item;
      edit = TextFieldState(
        text: item.text?.val,
        onChanged: (s) => item.attachments.isEmpty && s.text.isEmpty
            ? s.status.value = RxStatus.error()
            : s.status.value = RxStatus.empty(),
        onSubmitted: (s) async {
          if (s.text == item.text?.val) {
            editedMessage.value = null;
            edit = null;
          } else if (s.text.isNotEmpty || item.attachments.isNotEmpty) {
            ChatMessageText? text;
            if (s.text.isNotEmpty) {
              text = ChatMessageText(s.text);
            }

            try {
              await _chatService.editChatMessage(item, text);
              editedMessage.value = null;
              edit = null;

              _typingSubscription?.cancel();
              _typingSubscription = null;
              _typingTimer?.cancel();

              if (send.isEmpty.isFalse) {
                send.focus.requestFocus();
              }
            } on EditChatMessageException catch (e) {
              MessagePopup.error(e);
            } catch (e) {
              MessagePopup.error(e);
              rethrow;
            }
          }
        },
      )..focus.requestFocus();
    }
  }

  /// Fetches the local [chat] value from [_chatService] by the provided [id].
  Future<void> _fetchChat() async {
    status.value = RxStatus.loading();
    chat = await _chatService.get(id);
    if (chat == null) {
      status.value = RxStatus.empty();
    } else {
      _messagesWorker ??= ever(
        chat!.messages,
        (List<Rx<ChatItem>> msgs) {
          if (atBottom) {
            Future.delayed(
              Duration.zero,
              () => SchedulerBinding.instance.addPostFrameCallback(
                (_) async {
                  if (listController.hasClients) {
                    try {
                      _ignorePositionChanges = true;
                      await listController.animateTo(
                        listController.position.maxScrollExtent,
                        duration: 100.milliseconds,
                        curve: Curves.ease,
                      );
                    } finally {
                      _ignorePositionChanges = false;
                    }
                  }
                },
              ),
            );
          }
        },
      );

      listController.sliverController.onPaintItemPositionsCallback =
          (height, positions) {
        if (positions.isNotEmpty) {
          _topVisibleItem = positions.first;
        }
      };

      _readWorker ??= debounce(
        lastVisibleItem,
        (ChatItem? item) {
          if (item != null) {
            readChat(item);
          }
        },
        time: 1.seconds,
      );

      // If [RxChat.status] is not successful yet, populate the
      // [_messageInitializedWorker] to determine the initial messages list
      // index and offset.
      if (!chat!.status.value.isSuccess) {
        _messageInitializedWorker = ever(chat!.status, (RxStatus status) {
          if (_messageInitializedWorker != null) {
            if (status.isSuccess) {
              _messageInitializedWorker?.dispose();
              _messageInitializedWorker = null;

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

      await chat!.fetchMessages(id);

      // Required in order for [Hive.boxEvents] to add the messages.
      await Future.delayed(Duration.zero);

      var lastRead = lastReadItem.value;
      _determineLastRead();

      // Scroll to the last message if [_lastRead] was updated. Otherwise,
      // [FlutterListViewDelegate.keepPosition] handles this as the last read
      // item is already in the list.
      if (lastRead?.value.id != lastReadItem.value?.value.id) {
        _scrollToLast();
      }

      status.value = RxStatus.success();
    }
  }

  /// Returns an [User] from [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Marks the [chat] as read for the authenticated [MyUser] until the [item]
  /// inclusively.
  Future<void> readChat(ChatItem item) async {
    if (!chat!.chat.value.isReadBy(item, me)) {
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
    bool offsetBasedOnBottom = false,
    double offset = 0,
  }) async {
    int index = chat!.messages.indexWhere((e) => e.value.id == id);
    if (index != -1) {
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

      if (_topVisibleItem != null) {
        _itemToReturnTo = chat!.messages[_topVisibleItem!.index].value;
        _offsetToReturnTo = _topVisibleItem!.offset;
      } else {
        _itemToReturnTo = null;
      }

      var index = chat!.messages.length - 1;
      try {
        _ignorePositionChanges = true;
        await listController.sliverController.animateToIndex(
          index,
          offset: 0,
          offsetBasedOnBottom: true,
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
        await animateTo(_itemToReturnTo!.id, offset: _offsetToReturnTo);
      } finally {
        _ignorePositionChanges = false;
        _updateFabStates();
      }
    }
  }

  /// Opens a media choose popup and adds the selected files to the
  /// [attachments].
  Future<void> pickMedia() =>
      _pickAttachment(PlatformUtils.isIOS ? FileType.media : FileType.image);

  /// Opens the camera app and adds the captured image to the [attachments].
  Future<void> pickImageFromCamera() async {
    // TODO: Remove the limitations when bigger files are supported on backend.
    final XFile? photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );

    if (photo != null) {
      _addXFileAttachment(photo);
    }
  }

  /// Opens the camera app and adds the captured video to the [attachments].
  Future<void> pickVideoFromCamera() async {
    // TODO: Remove the limitations when bigger files are supported on backend.
    final XFile? video = await ImagePicker().pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 15),
    );

    if (video != null) {
      _addXFileAttachment(video);
    }
  }

  /// Opens a file choose popup and adds the selected files to the
  /// [attachments].
  Future<void> pickFile() => _pickAttachment(FileType.any);

  /// Adds the specified [details] files to the [attachments].
  void dropFiles(DropDoneDetails details) async {
    for (var file in details.files) {
      addPlatformAttachment(PlatformFile(
        path: file.path,
        name: file.name,
        size: await file.length(),
        readStream: file.openRead(),
      ));
    }
  }

  /// Puts a [text] into the clipboard and shows a snackbar.
  void copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    MessagePopup.success('label_copied_to_clipboard'.l10n);
  }

  /// Returns a [List] of [Attachment]s representing a collection of all the
  /// media files of this [chat].
  List<Attachment> calculateGallery() {
    final List<Attachment> attachments = [];

    for (var m in chat?.messages ?? <Rx<ChatItem>>[]) {
      if (m.value is ChatMessage) {
        final ChatMessage msg = m.value as ChatMessage;
        attachments.addAll(msg.attachments.where(
          (e) => e is ImageAttachment || (e is FileAttachment && e.isVideo),
        ));
      } else if (m.value is ChatForward) {
        final ChatForward msg = m.value as ChatForward;
        final ChatItem item = msg.item;

        if (item is ChatMessage) {
          attachments.addAll(item.attachments.where(
            (e) => e is ImageAttachment || (e is FileAttachment && e.isVideo),
          ));
        }
      }
    }

    return attachments;
  }

  /// Keeps the [ChatService.keepTyping] subscription up indicating the ongoing
  /// typing in this [chat].
  void keepTyping() async {
    _typingSubscription ??= (await _chatService.keepTyping(id)).listen((_) {});
    _typingTimer?.cancel();
    _typingTimer = Timer(_typingDuration, () {
      _typingSubscription?.cancel();
      _typingSubscription = null;
    });
  }

  /// Constructs a [NativeFile] from the specified [PlatformFile] and adds it
  /// to the [attachments].
  @visibleForTesting
  Future<void> addPlatformAttachment(PlatformFile platformFile) async {
    NativeFile nativeFile = NativeFile.fromPlatformFile(platformFile);
    await _addAttachment(nativeFile);
  }

  /// Constructs a [NativeFile] from the specified [XFile] and adds it to the
  /// [attachments].
  Future<void> _addXFileAttachment(XFile xFile) async {
    NativeFile nativeFile = NativeFile.fromXFile(xFile, await xFile.length());
    await _addAttachment(nativeFile);
  }

  /// Constructs a [LocalAttachment] from the specified [file] and adds it to
  /// the [attachments] list.
  ///
  /// May be used to test a [file] upload since [FilePicker] can't be mocked.
  Future<void> _addAttachment(NativeFile file) async {
    if (file.size < maxAttachmentSize) {
      try {
        var attachment = LocalAttachment(file, status: SendingStatus.sending);
        attachments.add(attachment);

        Attachment uploaded = await _chatService.uploadAttachment(attachment);

        int index = attachments.indexOf(attachment);
        if (index != -1) {
          attachments[index] = uploaded;
        }
      } on UploadAttachmentException catch (e) {
        MessagePopup.error(e);
      } on ConnectionException {
        // No-op.
      }
    } else {
      MessagePopup.error('err_size_too_big'.l10n);
    }
  }

  /// Opens a file choose popup of the specified [type] and adds the selected
  /// files to the [attachments].
  Future<void> _pickAttachment(FileType type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: true,
      withReadStream: true,
    );

    if (result != null && result.files.isNotEmpty) {
      for (PlatformFile e in result.files) {
        addPlatformAttachment(e);
      }
    }
  }

  /// Plays the message sent sound.
  void _playMessageSent() {
    runZonedGuarded(
      () => _audioPlayer?.play(
        AssetSource('audio/message_sent.mp3'),
        position: Duration.zero,
        mode: PlayerMode.lowLatency,
      ),
      (e, _) {
        if (!e.toString().contains('NotAllowedError')) {
          throw e;
        }
      },
    );
  }

  /// Updates the [canGoDown] and [canGoBack] indicators based on the
  /// [FlutterListViewController.position] value.
  void _updateFabStates() {
    if (listController.hasClients && !_ignorePositionChanges) {
      if (listController.position.pixels <
          listController.position.maxScrollExtent -
              MediaQuery.of(router.context!).size.height * 2 +
              200) {
        canGoDown.value = true;
      } else {
        canGoDown.value = false;
      }

      if (canGoBack.isTrue) {
        canGoBack.value = false;
      }
    }
  }

  /// Initializes the [_audioPlayer].
  Future<void> _initAudio() async {
    try {
      _audioPlayer = AudioPlayer(playerId: 'chatPlayer$id');
      await AudioCache.instance.loadAll(['audio/message_sent.mp3']);
    } on MissingPluginException {
      _audioPlayer = null;
    }
  }

  /// Determines the [lastReadItem] of the authenticated [MyUser] from the
  /// [RxChat.messages] list.
  void _determineLastRead() {
    PreciseDateTime? myRead = chat!.chat.value.lastReads
        .firstWhereOrNull((e) => e.memberId == me)
        ?.at;
    if (chat!.chat.value.unreadCount != 0 && myRead != null) {
      lastReadItem.value = chat!.messages.firstWhereOrNull(
          (e) => myRead.isBefore(e.value.at) && e.value.authorId != me);
    }
  }

  /// Calculates a [_ListViewIndexCalculationResult] of a [FlutterListView].
  _ListViewIndexCalculationResult _calculateListViewIndex(
      [bool fixMotion = true]) {
    int index = 0;
    double offset = 0;

    if (itemId != null) {
      int i = chat!.messages.indexWhere((e) => e.value.id == itemId);
      if (i != -1) {
        index = i;
        offset = (MediaQuery.of(router.context!).size.height) / 3;
      }
    } else {
      PreciseDateTime? myRead = chat!.chat.value.lastReads
          .firstWhereOrNull((e) => e.memberId == me)
          ?.at;

      if (chat?.messages.isEmpty == false) {
        if (chat!.chat.value.unreadCount == 0) {
          index = chat!.messages.length - 1;
          offset = 0;
        } else if (myRead != null) {
          int i = chat!.messages.indexOf(lastReadItem.value);
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
  void _scrollToLast() {
    Future.delayed(Duration.zero, () {
      if (listController.hasClients) {
        if (chat?.messages.isEmpty == false) {
          var result = _calculateListViewIndex(false);

          listController.jumpTo(
            listController.position.pixels >
                    listController.position.maxScrollExtent
                ? listController.position.maxScrollExtent
                : listController.position.pixels,
          );

          SchedulerBinding.instance.addPostFrameCallback((_) {
            listController.sliverController.animateToIndex(
              result.index,
              offset: 0,
              offsetBasedOnBottom: true,
              duration: 200.milliseconds,
              curve: Curves.ease,
            );
          });
        }
      } else {
        _scrollToLast();
      }
    });
  }
}

/// Extension adding [ChatView] related wrappers and helpers.
extension ChatViewExt on Chat {
  /// Returns text represented title of this [Chat].
  String getTitle(Iterable<User> users, UserId? me) {
    String title = 'dot'.l10n * 3;

    switch (kind) {
      case ChatKind.monolog:
        title = 'label_chat_monolog'.l10n;
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
    if (authorId == me) {
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

/// Result of a [FlutterListView] initial index and offset calculation.
class _ListViewIndexCalculationResult {
  const _ListViewIndexCalculationResult(this.index, this.offset);

  /// Initial index of an item in the [FlutterListView].
  final int index;

  /// Initial [FlutterListView] offset.
  final double offset;
}

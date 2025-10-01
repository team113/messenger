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
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/api/backend/schema.dart'
    show CropAreaInput, PointInput, UpdateChatAvatarErrorCode;
import '/domain/model/chat.dart';
import '/domain/model/file.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/settings.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/ui/page/home/page/my_profile/crop_avatar/view.dart';
import '/ui/widget/text_field.dart';
import '/ui/worker/cache.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';

export 'view.dart';

/// Controller of the [Routes.chatInfo] page.
class ChatInfoController extends GetxController {
  ChatInfoController(
    this.chatId,
    this._chatService,
    this._authService,
    this._callService,
    this._myUserService,
    this._settingsRepo,
  );

  /// ID of the [Chat] this page is about.
  final ChatId chatId;

  /// Reactive state of the [Chat] this page is about.
  RxChat? chat;

  /// Status of the [chat] fetching.
  ///
  /// May be:
  /// - `status.isLoading`, meaning [chat] is being fetched from the service.
  /// - `status.isEmpty`, meaning [chat] with specified [id] was not found.
  /// - `status.isSuccess`, meaning [chat] is successfully fetched.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.loading());

  /// Status of the [Chat.avatar] upload or removal.
  final Rx<RxStatus> avatarUpload = Rx<RxStatus>(RxStatus.empty());

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [ItemScrollController] of the page's [ScrollablePositionedList].
  final ItemScrollController itemScrollController = ItemScrollController();

  /// [ItemPositionsListener] of the page's [ScrollablePositionedList].
  final ItemPositionsListener positionsListener =
      ItemPositionsListener.create();

  /// [ScrollController] to pass to a members [ListView].
  final ScrollController membersScrollController = ScrollController();

  /// [Chat.name] field state.
  late final TextFieldState name;

  /// [GlobalKey] of an [AvatarWidget] displayed used to open a [PlayerView].
  final GlobalKey avatarKey = GlobalKey();

  /// [GlobalKey] of the more [ContextMenuRegion] button.
  final GlobalKey moreKey = GlobalKey();

  /// [TextFieldState] for report reason.
  final TextFieldState reporting = TextFieldState();

  /// Index of an item from the page's [ScrollablePositionedList] that should
  /// be highlighted.
  final RxnInt highlighted = RxnInt();

  /// [CropAreaInput] of the currently edited [ChatAvatar] to upload in
  /// [submitAvatar].
  final Rx<CropAreaInput?> avatarCrop = Rx(null);

  /// [NativeFile] of the currently edited [ChatAvatar] to upload in
  /// [submitAvatar].
  final Rx<NativeFile?> avatarImage = Rx(null);

  /// Indicator whether the currently edited [ChatAvatar] should be deleted in
  /// [submitAvatar].
  final RxBool avatarDeleted = RxBool(false);

  /// [Chat]s service used to get the [chat] value.
  final ChatService _chatService;

  /// [AuthService] used to get [me] value.
  final AuthService _authService;

  /// [CallService] used to start a call in the [chat].
  final CallService _callService;

  /// [MyUserService] maintaining the [myUser].
  final MyUserService _myUserService;

  /// Settings repository, used to retrieve the [background].
  final AbstractSettingsRepository _settingsRepo;

  /// Worker to react on [chat] changes.
  Worker? _worker;

  /// Subscription for the [chat] changes.
  StreamSubscription? _chatSubscription;

  /// Subscription for the [RxChat.members] changes.
  StreamSubscription? _membersSubscription;

  /// Indicator whether the [_scrollListener] is already invoked during the
  /// current frame.
  bool _scrollIsInvoked = false;

  /// [Sentry] transaction monitoring this [ChatInfoController] readiness.
  final ISentrySpan _ready = Sentry.startTransaction(
    'ui.chat_info.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
  );

  /// [Sentry] span of [_ready] intended to be populated during [_applyChat] and
  /// [_fetchMembers].
  ISentrySpan? _fetched;

  /// [Timer] resetting the [highlight] value after the [_highlightTimeout] has
  /// passed.
  Timer? _highlightTimer;

  /// [Duration] of the highlighting.
  static const Duration _highlightTimeout = Duration(seconds: 1);

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Indicates whether the [chat] is a monolog.
  bool get isMonolog => chat?.chat.value.isMonolog ?? false;

  /// Indicates whether the group's [chat] is a favorite.
  bool get isFavorite => chat?.chat.value.favoritePosition != null;

  /// Indicates whether the [Chat.members] have a next page.
  RxBool get haveNext => chat?.members.hasNext ?? RxBool(false);

  /// Returns the current background's [Uint8List] value.
  Rx<Uint8List?> get background => _settingsRepo.background;

  /// Indicates whether the [Chat.avatar] and [Chat.name] can be edited.
  bool get canEdit => !isMonolog;

  @override
  void onInit() {
    membersScrollController.addListener(_scrollListener);

    name = TextFieldState(
      text: chat?.chat.value.name?.val,
      onFocus: (_) async => await _updateChatName(),
    );

    _fetched?.finish();
    _fetched = _ready.startChild('fetch');

    try {
      final FutureOr<RxChat?> fetched = _chatService.get(chatId);

      if (fetched is RxChat?) {
        _applyChat(fetched);
      } else {
        status.value = RxStatus.loading();
        fetched.then(_applyChat);
      }
    } catch (e) {
      _ready.throwable = e;
      _ready.finish(status: const SpanStatus.internalError());
      rethrow;
    }

    super.onInit();
  }

  @override
  void onClose() {
    _worker?.dispose();
    _highlightTimer?.cancel();
    _chatSubscription?.cancel();
    _membersSubscription?.cancel();
    membersScrollController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Removes [User] identified by the provided [userId] from the [chat].
  Future<void> removeChatMember(UserId userId) async {
    try {
      await _chatService.removeChatMember(chatId, userId);
      if (userId == me && router.route.startsWith('${Routes.chats}/$chatId')) {
        router.home();
      }
    } on RemoveChatMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Starts a [ChatCall] in this [Chat] [withVideo] or without.
  Future<void> call(bool withVideo) async {
    try {
      await _callService.call(chatId, withVideo: withVideo);
    } on JoinChatCallException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Opens a file choose popup and updates the [Chat.avatar] with the selected
  /// image, if any.
  Future<void> pickAvatar() async {
    final FilePickerResult? result = await PlatformUtils.pickFiles(
      type: FileType.custom,
      allowedExtensions: NativeFile.images,
      allowMultiple: false,
      withData: true,
      lockParentWindow: true,
    );

    if (result != null) {
      final PlatformFile file = result.files.first;

      final CropAreaInput? crop = await CropAvatarView.show(
        router.context!,
        file.bytes!,
      );
      if (crop == null) {
        return;
      }

      await updateChatAvatar(file, crop: crop);
    }
  }

  /// Resets the [Chat.avatar] to `null`.
  Future<void> deleteAvatar() => updateChatAvatar(null);

  /// Updates the [Chat.avatar] with the provided [image], or resets it to
  /// `null`.
  Future<void> updateChatAvatar(
    PlatformFile? image, {
    CropAreaInput? crop,
  }) async {
    avatarUpload.value = RxStatus.loading();

    try {
      await _chatService.updateChatAvatar(
        chatId,
        file: image == null ? null : NativeFile.fromPlatformFile(image),
        crop: crop,
      );

      avatarUpload.value = RxStatus.empty();
    } on UpdateChatAvatarException catch (e) {
      switch (e.code) {
        case UpdateChatAvatarErrorCode.dialog:
        case UpdateChatAvatarErrorCode.invalidCropCoordinates:
        case UpdateChatAvatarErrorCode.invalidCropPoints:
        case UpdateChatAvatarErrorCode.unknownChat:
          avatarUpload.value = RxStatus.error('err_data_transfer'.l10n);

        case UpdateChatAvatarErrorCode.malformed:
        case UpdateChatAvatarErrorCode.unsupportedFormat:
        case UpdateChatAvatarErrorCode.invalidSize:
        case UpdateChatAvatarErrorCode.invalidDimensions:
        case UpdateChatAvatarErrorCode.artemisUnknown:
          avatarUpload.value = RxStatus.error(e.toMessage());
      }
    } catch (e) {
      avatarUpload.value = RxStatus.empty();
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Marks the [chat] as favorited.
  Future<void> favoriteChat() async {
    try {
      await _chatService.favoriteChat(chatId);
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
      await _chatService.unfavoriteChat(chatId);
    } on UnfavoriteChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Hides the [chat].
  Future<void> hideChat() async {
    try {
      await _chatService.hideChat(chatId);
    } on HideChatException catch (e) {
      MessagePopup.error(e);
    } on UnfavoriteChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  // TODO: Replace with GraphQL mutation when implemented.
  /// Reports the [chat].
  Future<void> reportChat() async {
    // TODO: Open support chat.
  }

  /// Clears all the [ChatItem]s of the [chat].
  Future<void> clearChat() async {
    try {
      await _chatService.clearChat(chatId);
    } on ClearChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Joins an [OngoingCall] happening in the [chat].
  Future<void> joinCall() => _callService.join(chatId, withVideo: false);

  /// Redials the [User] identified by its [userId].
  Future<void> redialChatCallMember(UserId userId) async {
    if (userId == me) {
      await _callService.join(chatId);
      return;
    }

    try {
      await _callService.redialChatCallMember(chatId, userId);
    } on RedialChatCallMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Mutes the [chat].
  Future<void> muteChat() async {
    try {
      await _chatService.toggleChatMute(
        chat?.id ?? chatId,
        MuteDuration.forever(),
      );
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
      await _chatService.toggleChatMute(chat?.id ?? chatId, null);
    } on ToggleChatMuteException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Removes the specified [User] from a [OngoingCall] happening in the [chat].
  Future<void> removeChatCallMember(UserId userId) async {
    try {
      await _callService.removeChatCallMember(chatId, userId);
    } on RemoveChatCallMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug]
  /// and deletes the current active [ChatDirectLink] of the given [Chat]-group
  /// (if any).
  Future<void> createChatDirectLink(ChatDirectLinkSlug? slug) async {
    await _chatService.createChatDirectLink(chatId, slug!);
  }

  /// Deletes the current [ChatDirectLink] of the given [Chat]-group.
  Future<void> deleteChatDirectLink() async {
    await _chatService.deleteChatDirectLink(chatId);
  }

  /// Uploads the current edits ([avatarCrop], [avatarImage] and
  /// [avatarDeleted]).
  Future<void> submitAvatar() async {
    if (avatarCrop.value != null ||
        avatarImage.value != null ||
        avatarDeleted.value) {
      if (avatarCrop.value == null && chat?.chat.value.avatar?.crop != null) {
        avatarCrop.value = CropAreaInput(
          bottomRight: PointInput(
            x: chat!.chat.value.avatar!.crop!.bottomRight.x,
            y: chat!.chat.value.avatar!.crop!.bottomRight.y,
          ),
          topLeft: PointInput(
            x: chat!.chat.value.avatar!.crop!.topLeft.x,
            y: chat!.chat.value.avatar!.crop!.topLeft.y,
          ),
          angle: chat?.chat.value.avatar?.crop?.angle,
        );
      }

      if (avatarImage.value == null && !avatarDeleted.value) {
        final ImageFile? file = chat?.chat.value.avatar?.original;

        if (file != null) {
          final CacheEntry cache = await CacheWorker.instance.get(
            url: file.url,
            checksum: file.checksum,
          );

          avatarImage.value = NativeFile(
            name: file.name,
            size: cache.bytes!.lengthInBytes,
            bytes: cache.bytes,
          );
        }
      }

      if (avatarImage.value != null || avatarDeleted.value) {
        await _chatService.updateChatAvatar(
          chatId,
          file: avatarImage.value,
          crop: avatarCrop.value,
        );
      }
    }

    avatarImage.value = null;
    avatarCrop.value = null;
    avatarDeleted.value = false;
  }

  /// Highlights the item with the provided [index].
  void highlight(int index) {
    highlighted.value = index;

    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightTimeout, () {
      highlighted.value = null;
    });
  }

  /// Opens the [CropAvatarView] to update the [MyUser.avatar] with the
  /// [CropAreaInput] returned from it.
  Future<void> editAvatar() async {
    final ImageFile? file = chat?.chat.value.avatar?.original;
    if (file == null) {
      return;
    }

    avatarUpload.value = RxStatus.loading();

    try {
      final CacheEntry cache = await CacheWorker.instance.get(
        url: file.url,
        checksum: file.checksum,
      );

      if (cache.bytes != null) {
        final CropAreaInput? crop = await CropAvatarView.show(
          router.context!,
          cache.bytes!,
        );

        if (crop != null) {
          await _chatService.updateChatAvatar(
            chatId,
            file: NativeFile(
              name: file.name,
              size: cache.bytes!.lengthInBytes,
              bytes: cache.bytes,
            ),
            crop: crop,
          );
        }
      }
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }

  /// Applies the provided [RxChat] to the [chat] initializing all its
  /// listeners, etc.
  void _applyChat(RxChat? chat) {
    this.chat = chat;

    if (chat == null) {
      status.value = RxStatus.empty();
    } else {
      _chatSubscription = chat.updates.listen((_) {});

      name.unchecked = chat.chat.value.name?.val;

      _worker = ever(chat.chat, (Chat chat) {
        if (!name.focus.hasFocus &&
            !name.changed.value &&
            name.editable.value) {
          name.unchecked = chat.name?.val;
        }
      });

      _membersSubscription = chat.members.items.changes.listen((event) {
        switch (event.op) {
          case OperationKind.added:
          case OperationKind.updated:
            // No-op.
            break;

          case OperationKind.removed:
            _scrollListener();
            break;
        }
      });

      status.value = RxStatus.success();
      _fetched?.finish();

      SchedulerBinding.instance.addPostFrameCallback((_) => _fetchMembers());
    }
  }

  /// Ensures the [RxChat.members] are fetched.
  Future<void> _fetchMembers() async {
    // If [RxChat.members] has next.
    if (chat!.members.hasNext.value) {
      _fetched = _ready.startChild('members.around');

      _ready.setTag(
        'members',
        '${chat!.members.length >= chat!.members.perPage}',
      );

      await chat!.members.around();

      _fetched?.finish();
      _fetched = null;

      SchedulerBinding.instance.addPostFrameCallback((_) => _ready.finish());
    }
  }

  /// Requests the next page of [ChatMember]s based on the
  /// [ScrollController.position] value.
  void _scrollListener() {
    if (!_scrollIsInvoked) {
      _scrollIsInvoked = true;

      SchedulerBinding.instance.addPostFrameCallback((_) async {
        _scrollIsInvoked = false;

        if (membersScrollController.hasClients &&
            haveNext.isTrue &&
            chat?.members.nextLoading.value == false &&
            membersScrollController.position.pixels >
                membersScrollController.position.maxScrollExtent - 500) {
          await chat?.members.next();
        }
      });
    }
  }

  /// Renames the [chat] to a [ChatName] specified in the [name] field.
  Future<void> _updateChatName() async {
    name.focus.unfocus();

    if (name.text == chat?.chat.value.name?.val) {
      name.unsubmit();
      return;
    }

    ChatName? chatName;
    try {
      chatName = name.text.isEmpty ? null : ChatName(name.text);
    } on FormatException catch (_) {
      name.status.value = RxStatus.empty();
      name.error.value = 'err_incorrect_input'.l10n;
      name.unsubmit();
      return;
    }

    if (name.error.value == null || name.resubmitOnError.isTrue) {
      name.status.value = RxStatus.loading();
      name.editable.value = false;

      try {
        await _chatService.renameChat(chat!.chat.value.id, chatName);
        name.error.value = null;
        name.unsubmit();
      } on RenameChatException catch (e) {
        name.error.value = e.toString();
      } catch (e) {
        name.resubmitOnError.value = true;
        name.error.value = 'err_data_transfer'.l10n;
        rethrow;
      } finally {
        name.status.value = RxStatus.empty();
        name.editable.value = true;
      }
    }
  }
}

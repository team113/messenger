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
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/native_file.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart'
    show
        CallAlreadyExistsException,
        CallAlreadyJoinedException,
        CallIsInPopupException;
import '/domain/repository/chat.dart';
import '/domain/repository/settings.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

export 'view.dart';

/// Controller of the [Routes.chatInfo] page.
class ChatInfoController extends GetxController {
  ChatInfoController(
    this.chatId,
    this._chatService,
    this._authService,
    this._callService,
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
  final Rx<RxStatus> avatar = Rx<RxStatus>(RxStatus.empty());

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Indicator whether the editing mode is enabled.
  final RxBool editing = RxBool(false);

  /// List of [UserId]s that are being removed from the [chat].
  final RxList<UserId> membersOnRemoval = RxList([]);

  /// [Chat.name] field state.
  late final TextFieldState name;

  /// [Chat.directLink] field state.
  late final TextFieldState link;

  /// [GlobalKey] of an [AvatarWidget] displayed used to open a [GalleryPopup].
  final GlobalKey avatarKey = GlobalKey();

  /// [GlobalKey] of the more [ContextMenuRegion] button.
  final GlobalKey moreKey = GlobalKey();

  /// [Chat]s service used to get the [chat] value.
  final ChatService _chatService;

  /// [AuthService] used to get [me] value.
  final AuthService _authService;

  /// [CallService] used to start a call in the [chat].
  final CallService _callService;

  /// Settings repository, used to retrieve the [background].
  final AbstractSettingsRepository _settingsRepo;

  /// Worker to react on [chat] changes.
  Worker? _worker;

  /// Subscription for the [chat] changes.
  StreamSubscription? _chatSubscription;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Indicates whether the [chat] is a monolog.
  bool get isMonolog => chat?.chat.value.isMonolog ?? false;

  /// Returns the current background's [Uint8List] value.
  Rx<Uint8List?> get background => _settingsRepo.background;

  @override
  void onInit() {
    name = TextFieldState(
      approvable: true,
      text: chat?.chat.value.name?.val,
      onChanged: (s) {
        try {
          if (s.text.isNotEmpty) {
            ChatName(s.text);
          }

          s.error.value = null;
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        s.error.value = null;
        s.focus.unfocus();

        if ((s.text.isEmpty && chat?.chat.value.name?.val == null) ||
            s.text == chat?.chat.value.name?.val) {
          s.unsubmit();
          return;
        }

        ChatName? name;
        try {
          name = s.text.isEmpty ? null : ChatName(s.text);
        } on FormatException catch (_) {
          s.status.value = RxStatus.empty();
          s.error.value = 'err_incorrect_input'.l10n;
          s.unsubmit();
          return;
        }

        if (s.error.value == null) {
          s.status.value = RxStatus.loading();
          s.editable.value = false;

          try {
            await _chatService.renameChat(chat!.chat.value.id, name);
            s.status.value = RxStatus.empty();
            s.unsubmit();
          } on RenameChatException catch (e) {
            s.status.value = RxStatus.empty();
            s.error.value = e.toString();
          } catch (e) {
            s.status.value = RxStatus.empty();
            MessagePopup.error(e.toString());
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    link = TextFieldState(
      approvable: true,
      editable: true,
      text: chat?.chat.value.directLink?.slug.val ??
          ChatDirectLinkSlug.generate(10).val,
      submitted: chat?.chat.value.directLink != null,
      onChanged: (s) {
        try {
          if (s.text.isNotEmpty) {
            ChatDirectLinkSlug(s.text);
          }

          s.error.value = null;
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        ChatDirectLinkSlug? slug;
        try {
          slug = ChatDirectLinkSlug(s.text);
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (slug == chat?.chat.value.directLink?.slug) {
          return;
        }

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _chatService.createChatDirectLink(chatId, slug!);
            s.status.value = RxStatus.empty();
          } on CreateChatDirectLinkException catch (e) {
            s.status.value = RxStatus.empty();
            s.error.value = e.toMessage();
          } catch (e) {
            s.status.value = RxStatus.empty();
            MessagePopup.error(e);
            s.unsubmit();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    super.onInit();
  }

  @override
  void onReady() {
    _fetchChat();
    super.onReady();
  }

  @override
  onClose() {
    _worker?.dispose();
    _chatSubscription?.cancel();
    super.onClose();
  }

  /// Removes [User] identified by the provided [userId] from the [chat].
  Future<void> removeChatMember(UserId userId) async {
    membersOnRemoval.add(userId);
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
    } finally {
      membersOnRemoval.remove(userId);
    }
  }

  /// Starts a [ChatCall] in this [Chat] [withVideo] or without.
  Future<void> call(bool withVideo) async {
    try {
      await _callService.call(chatId, withVideo: withVideo);
    } on CallAlreadyExistsException catch (e) {
      MessagePopup.error(e);
    } on JoinChatCallException catch (e) {
      MessagePopup.error(e);
    } on CallIsInPopupException catch (e) {
      MessagePopup.error(e);
    } on CallAlreadyJoinedException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Opens a file choose popup and updates the [Chat.avatar] with the selected
  /// image, if any.
  Future<void> pickAvatar() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withReadStream: !PlatformUtils.isWeb,
      withData: PlatformUtils.isWeb,
      lockParentWindow: true,
    );

    if (result != null) {
      updateChatAvatar(result.files.first);
    }
  }

  /// Resets the [Chat.avatar] to `null`.
  Future<void> deleteAvatar() => updateChatAvatar(null);

  /// Updates the [Chat.avatar] with the provided [image], or resets it to
  /// `null`.
  Future<void> updateChatAvatar(PlatformFile? image) async {
    avatar.value = RxStatus.loading();

    try {
      await _chatService.updateChatAvatar(
        chatId,
        file: image == null ? null : NativeFile.fromPlatformFile(image),
      );

      avatar.value = RxStatus.empty();
    } on UpdateChatAvatarException catch (e) {
      avatar.value = RxStatus.empty();
      MessagePopup.error(e);
    } catch (e) {
      avatar.value = RxStatus.empty();
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

  /// Fetches the [chat].
  Future<void> _fetchChat() async {
    status.value = RxStatus.loading();

    final FutureOr<RxChat?> fetched = _chatService.get(chatId);
    chat = fetched is RxChat? ? fetched : await fetched;

    if (chat == null) {
      status.value = RxStatus.empty();
    } else {
      _chatSubscription = chat!.updates.listen((_) {});

      name.unchecked = chat!.chat.value.name?.val;

      if (chat!.chat.value.directLink?.slug.val != null) {
        link.unchecked = chat!.chat.value.directLink?.slug.val;
      }

      _worker = ever(
        chat!.chat,
        (Chat chat) {
          if (!name.focus.hasFocus &&
              !name.changed.value &&
              name.editable.value) {
            name.unchecked = chat.name?.val;
          }

          if (!link.focus.hasFocus && !link.changed.value) {
            link.unchecked = chat.directLink?.slug.val;
          }
        },
      );

      status.value = RxStatus.success();
    }
  }
}

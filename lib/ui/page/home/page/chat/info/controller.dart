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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show CreateChatDirectLinkErrorCode;
import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/native_file.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/service/auth.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Controller of the [Routes.chatInfo] page.
class ChatInfoController extends GetxController {
  ChatInfoController(
    this.chatId,
    this._chatService,
    this._authService,
  );

  /// ID of the [Chat] this page is about.
  final ChatId chatId;

  /// [Chat]s service used to get the [chat] value.
  final ChatService _chatService;

  /// [AuthService] used to get [me] value.
  final AuthService _authService;

  /// List of [UserId]s that are being removed from the [chat].
  final RxList<UserId> membersOnRemoval = RxList([]);

  /// [Chat.name] field state.
  late final TextFieldState chatName;

  /// [Chat.directLink] field state.
  late final TextFieldState link;

  /// [Timer] to set the `RxStatus.empty` status of the [chatName] field.
  Timer? _nameTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [link] field.
  Timer? _linkTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [avatarStatus].
  Timer? _addAvatarTimer;

  /// Worker to react on [chat] changes.
  Worker? _worker;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Reactive state of the [Chat] this page is about.
  RxChat? chat;

  /// Status of the [chat] fetching.
  ///
  /// May be:
  /// - `status.isLoading`, meaning [chat] is being fetched from the service.
  /// - `status.isEmpty`, meaning [chat] with specified [id] was not found.
  /// - `status.isSuccess`, meaning [chat] is successfully fetched.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.loading());

  /// Status of the [Chat.avatar] update.
  final Rx<RxStatus> avatarStatus = Rx<RxStatus>(RxStatus.empty());

  @override
  void onInit() {
    chatName = TextFieldState(
      text: chat?.chat.value.name?.val,
      onChanged: (s) async {
        s.error.value = null;
        s.focus.unfocus();
        _nameTimer?.cancel();

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
            s.status.value = RxStatus.success();
            _nameTimer = Timer(const Duration(seconds: 1),
                () => s.status.value = RxStatus.empty());
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
      editable: true,
      onChanged: (s) {
        s.error.value = null;
        s.status.value = RxStatus.empty();
        s.unsubmit();
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
          _linkTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _chatService.createChatDirectLink(chatId, slug!);
            s.status.value = RxStatus.success();
            _linkTimer = Timer(const Duration(seconds: 1),
                () => s.status.value = RxStatus.empty());
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
    super.onClose();
  }

  /// Removes [User] identified by the provided [userId] from the [chat].
  Future<void> removeChatMember(UserId userId) async {
    membersOnRemoval.add(userId);
    try {
      await _chatService.removeChatMember(chatId, userId);
      if (userId == me && router.route.startsWith('${Routes.chat}/$chatId')) {
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

  /// Generates a new [Chat.directLink].
  Future<void> generateLink() async {
    ChatDirectLinkSlug slug = ChatDirectLinkSlug.generate(10);

    _linkTimer?.cancel();
    link.editable.value = false;
    link.status.value = RxStatus.loading();

    bool generated = false;
    while (!generated) {
      try {
        await _chatService.createChatDirectLink(chatId, slug);
        link.text = slug.val;
        link.status.value = RxStatus.success();
        link.error.value = null;
        _linkTimer = Timer(const Duration(seconds: 1),
            () => link.status.value = RxStatus.empty());
        generated = true;
      } on CreateChatDirectLinkException catch (e) {
        if (e.code != CreateChatDirectLinkErrorCode.occupied) {
          link.status.value = RxStatus.empty();
          link.error.value = e.toMessage();
          generated = true;
        }
      } catch (e) {
        link.status.value = RxStatus.empty();
        link.editable.value = true;
        MessagePopup.error(e);
        rethrow;
      }
    }

    link.editable.value = true;
  }

  /// Deletes the [Chat.directLink].
  Future<void> deleteLink() async {
    if (link.editable.isFalse) return;

    _linkTimer?.cancel();
    link.editable.value = false;
    link.status.value = RxStatus.loading();

    try {
      await _chatService.deleteChatDirectLink(chatId);
      link.status.value = RxStatus.success();
      link.error.value = null;
      _linkTimer = Timer(const Duration(seconds: 1),
          () => link.status.value = RxStatus.empty());
      link.text = '';
    } on DeleteChatDirectLinkException catch (e) {
      link.status.value = RxStatus.empty();
      link.error.value = e.toMessage();
    } catch (e) {
      link.status.value = RxStatus.empty();
      MessagePopup.error(e);
      rethrow;
    } finally {
      link.editable.value = true;
    }
  }

  /// Puts the [Chat.directLink] into the clipboard and shows a snackbar.
  void copyLink() {
    Clipboard.setData(
      ClipboardData(
        text:
            '${Config.origin}${Routes.chatDirectLink}/${chat!.chat.value.directLink!.slug.val}',
      ),
    );

    MessagePopup.success('label_copied_to_clipboard'.l10n);
  }

  /// Opens a file choose popup and updates the [Chat.avatar] with the selected
  /// [image].
  Future<void> pickGalleryItem() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withReadStream: true,
    );

    if (result != null) {
      _updateChatAvatar(result.files.first);
    }
  }

  /// Resets [Chat.avatar] to null.
  Future<void> removeChatAvatar() async => _updateChatAvatar(null);

  /// Updates the [Chat.avatar] field with the provided [image], or resets it to
  /// null.
  Future<void> _updateChatAvatar(PlatformFile? image) async {
    try {
      _addAvatarTimer?.cancel();
      avatarStatus.value = RxStatus.loading();
      await _chatService.uploadChatAvatar(
        chatId,
        file: (image == null) ? null : NativeFile.fromPlatformFile(image),
      );
      avatarStatus.value = RxStatus.success();
    } on UpdateChatAvatarException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      _addAvatarTimer = Timer(const Duration(seconds: 1),
          () => avatarStatus.value = RxStatus.empty());
    }
  }

  /// Fetches the [chat].
  void _fetchChat() async {
    status.value = RxStatus.loading();
    chat = await _chatService.get(chatId);
    if (chat == null) {
      status.value = RxStatus.empty();
    } else {
      chatName.unchecked = chat!.chat.value.name?.val;
      link.unchecked = chat!.chat.value.directLink?.slug.val;

      _worker = ever(
        chat!.chat,
        (Chat chat) {
          if (!chatName.focus.hasFocus) {
            chatName.unchecked = chat.name?.val;
          }
          if (!link.focus.hasFocus) {
            link.unchecked = chat.directLink?.slug.val;
          }
        },
      );

      status.value = RxStatus.success();
    }
  }
}

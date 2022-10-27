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

import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messenger/domain/service/contact.dart';

import '../../../../call/search/view.dart';
import '/api/backend/schema.dart' show ForwardChatItemsErrorCode;
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/native_file.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

export 'view.dart';

/// Controller of a [ChatForwardView].
class ChatForwardController extends GetxController {
  ChatForwardController(
    this._chatService,
    this._userService, {
    required this.from,
    required List<ChatItemQuote> quotes,
    this.text,
    RxList<Attachment>? attachments,
  })  : quotes = RxList(quotes),
        attachments = attachments ?? RxList();

  final Rx<SearchViewResults?> searchResults = Rx<SearchViewResults?>(null);

  /// ID of the [Chat] the [quotes] are forwarded from.
  final ChatId from;

  /// Indicator whether reply is hovered or not.
  final Rx<ChatItem?> hoveredReply = Rx(null);

  final String? text;

  /// [ChatItemQuote]s to be forwarded.
  final RxList<ChatItemQuote> quotes;

  /// State of a send message field.
  late final TextFieldState send;

  /// [Attachment]s to attach to the [quotes].
  final RxList<Attachment> attachments;

  /// [Chat]s service forwarding the [quotes].
  final ChatService _chatService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  @override
  void onInit() {
    send = TextFieldState(
      text: text,
      onChanged: (s) => s.error.value = null,
      focus: FocusNode(
        onKey: (FocusNode node, RawKeyEvent e) {
          if (e.logicalKey == LogicalKeyboardKey.enter &&
              e is RawKeyDownEvent) {
            if (e.isAltPressed || e.isControlPressed || e.isMetaPressed) {
              int cursor;

              if (send.controller.selection.isCollapsed) {
                cursor = send.controller.selection.base.offset;
                send.text =
                    '${send.text.substring(0, cursor)}\n${send.text.substring(cursor, send.text.length)}';
              } else {
                cursor = send.controller.selection.start;
                send.text =
                    '${send.text.substring(0, send.controller.selection.start)}\n${send.text.substring(send.controller.selection.end, send.text.length)}';
              }

              send.controller.selection =
                  TextSelection.fromPosition(TextPosition(offset: cursor + 1));
            } else if (!e.isShiftPressed) {
              send.submit();
              return KeyEventResult.handled;
            }
          }

          return KeyEventResult.ignored;
        },
      ),
    );

    super.onInit();
  }

  Future<void> forward() async {
    send.status.value = RxStatus.loading();
    send.editable.value = false;

    try {
      List<Future> uploads = attachments
          .whereType<LocalAttachment>()
          .map((e) => e.upload.value?.future)
          .whereNotNull()
          .toList();
      if (uploads.isNotEmpty) {
        await Future.wait(uploads);
      }

      if (attachments.whereType<LocalAttachment>().isNotEmpty) {
        throw const ConnectionException(ForwardChatItemsException(
          ForwardChatItemsErrorCode.unknownAttachment,
        ));
      }

      List<Future<void>> futures = [
        ...searchResults.value!.chats.map((e) async {
          return _chatService.forwardChatItems(
            from,
            e.chat.value.id,
            quotes,
            text: send.text == '' ? null : ChatMessageText(send.text),
            attachments: attachments.isEmpty
                ? null
                : attachments.map((a) => a.id).toList(),
          );
        }),
        ...searchResults.value!.users.map((e) async {
          Chat? dialog = e.user.value.dialog;
          dialog ??= (await _chatService.createDialogChat(e.id)).chat.value;
          return _chatService.forwardChatItems(
            from,
            dialog.id,
            quotes,
            text: send.text == '' ? null : ChatMessageText(send.text),
            attachments: attachments.isEmpty
                ? null
                : attachments.map((a) => a.id).toList(),
          );
        }),
        ...searchResults.value!.contacts.map((e) async {
          Chat? dialog = e.user.value?.user.value.dialog;
          dialog ??= (await _chatService.createDialogChat(e.user.value!.id))
              .chat
              .value;
          return _chatService.forwardChatItems(
            from,
            dialog.id,
            quotes,
            text: send.text == '' ? null : ChatMessageText(send.text),
            attachments: attachments.isEmpty
                ? null
                : attachments.map((a) => a.id).toList(),
          );
        })
      ];

      await Future.wait(futures);
    } on ForwardChatItemsException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      send.unsubmit();
    }
  }

  /// Returns an [User] from [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userService.get(id);

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

  /// Constructs a [NativeFile] from the specified [PlatformFile] and adds it
  /// to the [attachments].
  @visibleForTesting
  Future<void> addPlatformAttachment(PlatformFile platformFile) async {
    NativeFile nativeFile = NativeFile.fromPlatformFile(platformFile);
    await _addAttachment(nativeFile);
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

  /// Constructs a [NativeFile] from the specified [XFile] and adds it to the
  /// [attachments].
  Future<void> _addXFileAttachment(XFile xFile) async {
    NativeFile nativeFile = NativeFile.fromXFile(xFile, await xFile.length());
    await _addAttachment(nativeFile);
  }

  /// Constructs a [LocalAttachment] from the specified [file] and adds it to
  /// the [attachments] list.
  Future<void> _addAttachment(NativeFile file) async {
    if (file.size < ChatController.maxAttachmentSize) {
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
}

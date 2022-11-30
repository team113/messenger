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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/native_file.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';

export 'view.dart';

/// Controller of the [Routes.chatInfo] page.
class MessageFieldController extends GetxController {
  MessageFieldController(
    this._chatService,
    this._userService, {
    this.updateDraft,
  });

  /// [Attachment]s to be attached to a message.
  final RxObsList<MapEntry<GlobalKey, Attachment>> attachments =
      RxObsList<MapEntry<GlobalKey, Attachment>>();

  /// [ChatItem] being quoted to reply onto.
  final RxList<ChatItem> repliedMessages = RxList<ChatItem>();

  /// [ChatItemQuote]s to be forwarded.
  final RxList<ChatItemQuote> quotes = RxList<ChatItemQuote>();

  /// [Chat]s service used to get [chat] value.
  final ChatService _chatService;

  /// [ChatItem] being edited.
  final Rx<ChatItem?> editedMessage = Rx<ChatItem?>(null);

  /// [Attachment] being hovered.
  final Rx<Attachment?> hoveredAttachment = Rx(null);

  /// Replied [ChatItem] being hovered.
  final Rx<ChatItem?> hoveredReply = Rx(null);

  /// Indicator whether forwarding mode is enabled.
  final RxBool forwarding = RxBool(false);

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// Maximum allowed [NativeFile.size] of an [Attachment].
  static const int maxAttachmentSize = 15 * 1024 * 1024;

  /// Callback, called when need to update draft message.
  final void Function()? updateDraft;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

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

  /// Constructs a [NativeFile] from the specified [PlatformFile] and adds it
  /// to the [attachments].
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
        attachments.add(MapEntry(GlobalKey(), attachment));

        Attachment uploaded = await _chatService.uploadAttachment(attachment);

        int index = attachments.indexWhere((e) => e.value.id == attachment.id);
        if (index != -1) {
          attachments[index] = MapEntry(attachments[index].key, uploaded);
          updateDraft?.call();
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

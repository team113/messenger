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
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/domain/model/native_file.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'buttons.dart';

export 'view.dart';

/// Controller of a [MessageFieldView].
class MessageFieldController extends GetxController {
  MessageFieldController(
    this._chatService,
    this._userService, {
    this.onSubmit,
    this.onChanged,
    String? text,
    List<ChatItemQuoteInput> quotes = const [],
    List<Attachment> attachments = const [],
    bool canSend = true,
  })  : quotes = RxList(quotes),
        attachments =
            RxList(attachments.map((e) => MapEntry(GlobalKey(), e)).toList()) {
    field = TextFieldState(
      text: text,
      onChanged: (_) => onChanged?.call(),
      submitted: false,
      onSubmitted: (s) {
        if (canSend) {
          field.unsubmit();
          onSubmit?.call();
        }
      },
      focus: FocusNode(
        onKey: (FocusNode node, RawKeyEvent e) {
          if ((e.logicalKey == LogicalKeyboardKey.enter ||
                  e.logicalKey == LogicalKeyboardKey.numpadEnter) &&
              e is RawKeyDownEvent) {
            bool handled = e.isShiftPressed;

            if (!PlatformUtils.isWeb) {
              if (PlatformUtils.isMacOS || PlatformUtils.isWindows) {
                handled = handled || e.isAltPressed || e.isControlPressed;
              }
            }

            if (!handled) {
              if (e.isAltPressed ||
                  e.isControlPressed ||
                  e.isMetaPressed ||
                  e.isShiftPressed) {
                int cursor;

                if (field.controller.selection.isCollapsed) {
                  cursor = field.controller.selection.base.offset;
                  field.text =
                      '${field.text.substring(0, cursor)}\n${field.text.substring(cursor, field.text.length)}';
                } else {
                  cursor = field.controller.selection.start;
                  field.text =
                      '${field.text.substring(0, field.controller.selection.start)}\n${field.text.substring(field.controller.selection.end, field.text.length)}';
                }

                field.controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: cursor + 1),
                );
              } else {
                field.submit();
                return KeyEventResult.handled;
              }
            }
          }

          return KeyEventResult.ignored;
        },
      ),
    );

    _repliesWorker ??= ever(replied, (_) => onChanged?.call());
    _attachmentsWorker ??= ever(this.attachments, (_) => onChanged?.call());
    _editedWorker ??= ever(edited, (item) {
      if (item != null) {
        final ChatMessage msg = item as ChatMessage;

        field.text = msg.text?.val ?? '';
        this.attachments.value =
            msg.attachments.map((e) => MapEntry(GlobalKey(), e)).toList();
        replied.value =
            msg.repliesTo.map((e) => e.original).whereNotNull().toList();
      } else {
        field.text = '';
        this.attachments.clear();
        replied.clear();
      }

      onChanged?.call();
    });
  }

  /// Callback, called when this [MessageFieldController] is submitted.
  final void Function()? onSubmit;

  /// Callback, called on the [field], [attachments], [replied], [edited]
  /// changes.
  final void Function()? onChanged;

  /// [TextFieldState] for a [ChatMessageText].
  late final TextFieldState field;

  /// [Attachment]s to be attached to a message.
  late final RxList<MapEntry<GlobalKey, Attachment>> attachments;

  /// [ChatItem] being quoted to reply onto.
  final RxList<ChatItem> replied = RxList<ChatItem>();

  /// [ChatItemQuoteInput]s to be forwarded.
  late final RxList<ChatItemQuoteInput> quotes;

  /// [ChatItem] being edited.
  final Rx<ChatItem?> edited = Rx<ChatItem?>(null);

  final RxBool editing = RxBool(false);

  /// [Attachment] being hovered.
  final Rx<Attachment?> hoveredAttachment = Rx(null);

  /// Replied [ChatItem] being hovered.
  final Rx<ChatItem?> hoveredReply = Rx(null);

  /// Indicator whether forwarding mode is enabled.
  final RxBool forwarding = RxBool(false);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  final RxBool displayMore = RxBool(false);

  final GlobalKey globalKey = GlobalKey();
  late final RxList<ChatButton> panel = RxList([
    if (PlatformUtils.isMobile /*&& !PlatformUtils.isWeb*/) ...[
      TakePhotoButton(this),
      if (PlatformUtils.isAndroid) TakeVideoButton(this),
      GalleryButton(this),
      FileButton(this),
    ] else
      AttachmentButton(this),
    AudioMessageButton(this),
    VideoMessageButton(this),
    DonateButton(this),
    StickerButton(this),
  ]);

  final RxList<ChatButton> buttons = RxList([]);

  OverlayEntry? entry;

  /// Maximum allowed [NativeFile.size] of an [Attachment].
  static const int maxAttachmentSize = 15 * 1024 * 1024;

  /// [Chat]s service uploading the [attachments].
  final ChatService? _chatService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService? _userService;

  /// Worker reacting on the [replied] changes.
  Worker? _repliesWorker;

  /// Worker reacting on the [attachments] changes.
  Worker? _attachmentsWorker;

  /// Worker reacting on the [edited] changes.
  Worker? _editedWorker;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService?.me;

  @override
  void onClose() {
    entry?.remove();
    entry = null;

    _repliesWorker?.dispose();
    _attachmentsWorker?.dispose();
    _editedWorker?.dispose();

    clear();
    super.onClose();
  }

  /// Resets the [replied], [attachments] and [field].
  void clear() {
    editing.value = false;
    replied.clear();
    attachments.clear();
    forwarding.value = false;
    field.clear();
    field.unsubmit();
  }

  /// Returns an [User] from [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) async => await _userService?.get(id);

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

  /// Constructs a [NativeFile] from the specified [PlatformFile] and adds it
  /// to the [attachments].
  Future<void> addPlatformAttachment(PlatformFile platformFile) async {
    NativeFile nativeFile = NativeFile.fromPlatformFile(platformFile);
    await _addAttachment(nativeFile);
  }

  /// Toggles the [displayMore].
  void toggleMore() => displayMore.toggle();

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
  ///
  /// May be used to test a [file] upload since [FilePicker] can't be mocked.
  Future<void> _addAttachment(NativeFile file) async {
    if (file.size < maxAttachmentSize) {
      try {
        var attachment = LocalAttachment(file, status: SendingStatus.sending);
        attachments.add(MapEntry(GlobalKey(), attachment));

        Attachment uploaded =
            await _chatService?.uploadAttachment(attachment) ?? attachment;

        int index = attachments.indexWhere((e) => e.value.id == attachment.id);
        if (index != -1) {
          attachments[index] = MapEntry(attachments[index].key, uploaded);
          onChanged?.call();
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

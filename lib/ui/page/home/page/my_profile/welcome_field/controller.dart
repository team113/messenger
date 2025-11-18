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

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/native_file.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/welcome_message.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
import '/ui/page/home/page/chat/message_field/widget/buttons.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'component/more.dart';

export 'view.dart';

/// Controller of a [WelcomeFieldView].
class WelcomeFieldController extends GetxController {
  WelcomeFieldController(this._chatService, {this.onSubmit}) {
    field = TextFieldState(
      submitted: false,
      onSubmitted: (s) {
        field.unsubmit();
        onSubmit?.call();
      },
      focus: FocusNode(
        onKeyEvent: (_, KeyEvent e) =>
            MessageFieldController.handleNewLines(e, field),
      ),
    );

    _editedWorker ??= ever(edited, (item) {
      if (item != null) {
        field.text = item.text?.val ?? '';
        attachments.value = item.attachments
            .map((e) => MapEntry(GlobalKey(), e))
            .toList();
      } else {
        field.text = '';
        attachments.clear();
      }
    });
  }

  /// Callback, called when this [WelcomeFieldController] is submitted.
  final void Function()? onSubmit;

  /// [TextFieldState] for a [ChatMessageText].
  late final TextFieldState field;

  /// [Attachment]s to be attached to a message.
  final RxList<MapEntry<GlobalKey, Attachment>> attachments = RxList();

  /// [WelcomeMessage] being edited.
  final Rx<WelcomeMessage?> edited = Rx(null);

  /// [Attachment] being hovered.
  final Rx<Attachment?> hoveredAttachment = Rx(null);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Indicator whether the more panel is opened.
  final RxBool moreOpened = RxBool(false);

  /// [GlobalKey] of the text field itself.
  final GlobalKey fieldKey = GlobalKey();

  /// [ChatButton]s displayed in the more panel.
  late final RxList<ChatButton> panel = RxList([
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) ...[
      TakePhotoButton(pickImageFromCamera),
      if (PlatformUtils.isAndroid) TakeVideoButton(pickVideoFromCamera),
      GalleryButton(pickMedia),
      FileButton(pickFile),
    ] else
      AttachmentButton(pickFile),
  ]);

  /// Maximum allowed [NativeFile.size] of an [Attachment].
  static const int maxAttachmentSize = 15 * 1024 * 1024;

  /// [ChatService] used to upload [Attachment]s.
  final ChatService _chatService;

  /// [Worker] reacting on the [edited] changes.
  Worker? _editedWorker;

  /// [Worker] reacting on the [RouterState.routes] changes hiding the
  /// [_moreEntry].
  Worker? _routesWorker;

  /// [OverlayEntry] of the [MessageFieldMore].
  OverlayEntry? _moreEntry;

  @override
  void onInit() {
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.add(_onBack, ifNotYetIntercepted: true);
    }

    String route = router.route;
    _routesWorker = ever(router.routes, (routes) {
      if (router.route != route) {
        _moreEntry?.remove();
        _moreEntry = null;
      }
    });

    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await CustomMouseCursors.ensureInitialized();
    super.onReady();
  }

  @override
  void onClose() {
    _moreEntry?.remove();
    _editedWorker?.dispose();
    _routesWorker?.dispose();
    scrollController.dispose();

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.remove(_onBack);
    }

    super.onClose();
  }

  /// Resets the [attachments] and [field].
  void clear({bool unfocus = true}) {
    attachments.clear();
    field.clear(unfocus: unfocus);
    field.unsubmit();
  }

  /// Toggles the [moreOpened] and populates the [_moreEntry].
  void toggleMore() {
    if (moreOpened.isFalse) {
      _moreEntry = OverlayEntry(
        builder: (_) => MessageFieldMore(
          this,
          onDismissed: () {
            _moreEntry?.remove();
            _moreEntry = null;
          },
        ),
      );
      router.overlay!.insert(_moreEntry!);
    }

    moreOpened.toggle();
  }

  /// Opens a media choose popup and adds the selected files to the
  /// [attachments].
  Future<void> pickMedia() {
    field.focus.unfocus();
    return _pickAttachment(
      PlatformUtils.isIOS ? FileType.media : FileType.image,
    );
  }

  /// Opens the camera app and adds the captured image to the [attachments].
  Future<void> pickImageFromCamera() async {
    field.focus.unfocus();

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
    field.focus.unfocus();

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
  Future<void> pickFile() {
    field.focus.unfocus();
    return _pickAttachment(FileType.any);
  }

  /// Constructs a [NativeFile] from the specified [PlatformFile] and adds it
  /// to the [attachments].
  Future<void> addPlatformAttachment(PlatformFile platformFile) async {
    NativeFile nativeFile = NativeFile.fromPlatformFile(platformFile);
    await _addAttachment(nativeFile);
  }

  /// Opens a file choose popup of the specified [type] and adds the selected
  /// files to the [attachments].
  Future<void> _pickAttachment(FileType type) async {
    FilePickerResult? result = await PlatformUtils.pickFiles(
      type: type,
      allowMultiple: true,
      withReadStream: true,
      lockParentWindow: true,
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

        final Attachment? uploaded = await _chatService.uploadAttachment(
          attachment,
        );

        int index = attachments.indexWhere((e) => e.value.id == attachment.id);
        if (index != -1) {
          // If `Attachment` returned is `null`, then it was canceled.
          if (uploaded == null) {
            attachments.removeAt(index);
          } else {
            attachments[index] = MapEntry(attachments[index].key, uploaded);
          }
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

  /// Invokes [toggleMore], if [moreOpened].
  ///
  /// Intended to be used as a [BackButtonInterceptor] callback, thus returns
  /// `true`, if back button should be intercepted, or otherwise returns
  /// `false`.
  bool _onBack(bool _, RouteInfo _) {
    if (moreOpened.isTrue) {
      toggleMore();
      return true;
    }

    return false;
  }
}

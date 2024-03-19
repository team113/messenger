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

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'component/more.dart';
import 'widget/buttons.dart';

export 'view.dart';

/// Controller of a [MessageFieldView].
class MessageFieldController extends GetxController {
  MessageFieldController(
    this._chatService,
    this._userService,
    this._settingsRepository, {
    this.onSubmit,
    this.onChanged,
    this.onCall,
    String? text,
    List<ChatItemQuoteInput> quotes = const [],
    List<Attachment> attachments = const [],
  })  : quotes = RxList(quotes),
        attachments =
            RxList(attachments.map((e) => MapEntry(GlobalKey(), e)).toList()) {
    field = TextFieldState(
      text: text,
      onChanged: (_) => onChanged?.call(),
      submitted: false,
      onSubmitted: (s) {
        field.unsubmit();
        onSubmit?.call();
      },
      focus: FocusNode(
        onKeyEvent: (FocusNode node, KeyEvent e) {
          if ((e.logicalKey == LogicalKeyboardKey.enter ||
                  e.logicalKey == LogicalKeyboardKey.numpadEnter) &&
              e is KeyDownEvent) {
            final Set<PhysicalKeyboardKey> pressed =
                HardwareKeyboard.instance.physicalKeysPressed;

            final bool isShiftPressed = pressed.any((key) =>
                key == PhysicalKeyboardKey.shiftLeft ||
                key == PhysicalKeyboardKey.shiftRight);
            final bool isAltPressed = pressed.any((key) =>
                key == PhysicalKeyboardKey.altLeft ||
                key == PhysicalKeyboardKey.altRight);
            final bool isControlPressed = pressed.any((key) =>
                key == PhysicalKeyboardKey.controlLeft ||
                key == PhysicalKeyboardKey.controlRight);
            final bool isMetaPressed = pressed.any((key) =>
                key == PhysicalKeyboardKey.metaLeft ||
                key == PhysicalKeyboardKey.metaRight);

            bool handled = isShiftPressed;

            if (!PlatformUtils.isWeb) {
              if (PlatformUtils.isMacOS || PlatformUtils.isWindows) {
                handled = handled || isAltPressed || isControlPressed;
              }
            }

            if (!handled) {
              if (isAltPressed ||
                  isControlPressed ||
                  isMetaPressed ||
                  isShiftPressed) {
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
        field.text = item.text?.val ?? '';
        this.attachments.value =
            item.attachments.map((e) => MapEntry(GlobalKey(), e)).toList();
        replied.value =
            item.repliesTo.map((e) => e.original).whereNotNull().toList();
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

  /// Callback, called when make [OngoingCall] action is triggered.
  final void Function(bool)? onCall;

  /// [TextFieldState] for a [ChatMessageText].
  late final TextFieldState field;

  /// [Attachment]s to be attached to a message.
  late final RxList<MapEntry<GlobalKey, Attachment>> attachments;

  /// [ChatItem] being quoted to reply onto.
  final RxList<ChatItem> replied = RxList<ChatItem>();

  /// [ChatItemQuoteInput]s to be forwarded.
  late final RxList<ChatItemQuoteInput> quotes;

  /// [ChatItem] being edited.
  final Rx<ChatMessage?> edited = Rx<ChatMessage?>(null);

  /// [Attachment] being hovered.
  final Rx<Attachment?> hoveredAttachment = Rx(null);

  /// Replied [ChatItem] being hovered.
  final Rx<ChatItem?> hoveredReply = Rx(null);

  /// Indicator whether forwarding mode is enabled.
  final RxBool forwarding = RxBool(false);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Indicator whether the more panel is opened.
  final RxBool moreOpened = RxBool(false);

  /// [GlobalKey] of the text field itself.
  final GlobalKey fieldKey = GlobalKey();

  /// [ChatButton]s displayed in the more panel.
  late final RxList<ChatButton> panel = RxList([
    const AudioMessageButton(),
    const VideoMessageButton(),
    const DonateButton(),
    const StickerButton(),
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) ...[
      TakePhotoButton(pickImageFromCamera),
      if (PlatformUtils.isAndroid) TakeVideoButton(pickVideoFromCamera),
      GalleryButton(pickMedia),
      FileButton(pickFile),
    ] else
      AttachmentButton(pickFile),
    if (_settings?.value?.callButtonsPosition == CallButtonsPosition.more &&
        onCall != null) ...[
      AudioCallButton(() => onCall?.call(false)),
      VideoCallButton(() => onCall?.call(true)),
    ],
  ]);

  /// [ChatButton]s displayed (pinned) in the text field.
  late final RxList<ChatButton> buttons;

  /// Indicator whether any more [ChatButton] can be added to the [buttons].
  final RxBool canPin = RxBool(true);

  /// Maximum allowed [NativeFile.size] of an [Attachment].
  static const int maxAttachmentSize = 15 * 1024 * 1024;

  /// [Chat]s service uploading the [attachments].
  final ChatService? _chatService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService? _userService;

  /// [AbstractSettingsRepository], used to get the [buttons] value.
  final AbstractSettingsRepository? _settingsRepository;

  /// [Worker] reacting on the [replied] changes.
  Worker? _repliesWorker;

  /// [Worker] reacting on the [attachments] changes.
  Worker? _attachmentsWorker;

  /// [Worker] reacting on the [edited] changes.
  Worker? _editedWorker;

  /// [Worker] capturing any [buttons] changes to update the
  /// [ApplicationSettings.pinnedActions] value.
  Worker? _buttonsWorker;

  /// [Worker] capturing [inCall] changes to update the [panel] value.
  Worker? _inCallWorker;

  /// [Worker] reacting on the [RouterState.routes] changes hiding the
  /// [_moreEntry].
  Worker? _routesWorker;

  /// [OverlayEntry] of the [MessageFieldMore].
  OverlayEntry? _moreEntry;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService?.me;

  /// Returns the current [ApplicationSettings] value.
  Rx<ApplicationSettings?>? get _settings =>
      _settingsRepository?.applicationSettings;

  /// Sets the reactive [inCall] indicator, determining whether
  /// [AudioCallButton] and [VideoCallButton] buttons should be enabled or not.
  set inCall(RxBool inCall) {
    if (_settings?.value?.callButtonsPosition == CallButtonsPosition.more &&
        onCall != null) {
      _updateButtons(inCall.value);
      _inCallWorker?.dispose();
      _inCallWorker = ever(inCall, _updateButtons);
    }
  }

  @override
  void onInit() {
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.add(_onBack, ifNotYetIntercepted: true);
    }

    buttons = RxList(
      _toButtons(_settingsRepository?.applicationSettings.value?.pinnedActions),
    );

    _buttonsWorker = ever(buttons, (List<ChatButton> list) {
      _settingsRepository?.setPinnedActions(
        list.map((e) => e.runtimeType.toString()).toList(),
      );
    });

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
    _repliesWorker?.dispose();
    _attachmentsWorker?.dispose();
    _editedWorker?.dispose();
    _buttonsWorker?.dispose();
    _routesWorker?.dispose();
    _inCallWorker?.dispose();
    scrollController.dispose();

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.remove(_onBack);
    }

    super.onClose();
  }

  /// Resets the [replied], [attachments] and [field].
  void clear({bool unfocus = true}) {
    replied.clear();
    attachments.clear();
    forwarding.value = false;
    field.clear(unfocus: unfocus);
    field.unsubmit();
    onChanged?.call();
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

  /// Returns an [User] from [UserService] by the provided [id].
  FutureOr<RxUser?> getUser(UserId id) async => _userService?.get(id);

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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
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
    if (file.size < maxAttachmentSize && _chatService != null) {
      try {
        var attachment = LocalAttachment(file, status: SendingStatus.sending);
        attachments.add(MapEntry(GlobalKey(), attachment));

        Attachment uploaded = await _chatService.uploadAttachment(attachment);

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

  /// Invokes [toggleMore], if [moreOpened].
  ///
  /// Intended to be used as a [BackButtonInterceptor] callback, thus returns
  /// `true`, if back button should be intercepted, or otherwise returns
  /// `false`.
  bool _onBack(bool _, RouteInfo __) {
    if (moreOpened.isTrue) {
      toggleMore();
      return true;
    }

    return false;
  }

  /// Updates the [panel] and the [buttons] from that [panel], disabling or
  /// enabling the [AudioCallButton] and [VideoCallButton] according to the
  /// provided [inCall] value.
  void _updateButtons(bool inCall) {
    panel.value = panel.map((button) {
      if (button is AudioCallButton) {
        return AudioCallButton(inCall ? null : () => onCall?.call(false));
      }

      if (button is VideoCallButton) {
        return VideoCallButton(inCall ? null : () => onCall?.call(true));
      }

      return button;
    }).toList();

    buttons.value = _toButtons(
      _settingsRepository?.applicationSettings.value?.pinnedActions,
    );
  }

  /// Constructs a list of [ChatButton]s from the provided [list] of [String]s.
  List<ChatButton> _toButtons(List<String>? list) {
    final List<ChatButton>? persisted = list
        ?.map(
          (e) => panel.firstWhereOrNull((m) => m.runtimeType.toString() == e),
        )
        .whereNotNull()
        .toList();

    return persisted ?? [];
  }
}

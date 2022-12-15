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

import 'package:carousel_slider/carousel_controller.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/application_settings.dart';
import '/domain/model/chat.dart';
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

export 'view.dart';

/// Controller of the [Routes.me] page.
class MyProfileController extends GetxController {
  MyProfileController(
    this._myUserService,
    this._settingsRepo,
  );

  /// Status of an [uploadAvatar] or [deleteAvatar] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [uploadAvatar]/[deleteAvatar] is executing.
  /// - `status.isLoading`, meaning [uploadAvatar]/[deleteAvatar] is executing.
  final Rx<RxStatus> avatarUpload = Rx(RxStatus.empty());

  /// [CarouselController] of the [MyUser.gallery] used to jump between gallery
  /// items on [MyUser] updates.
  CarouselController? galleryController;

  /// [FlutterListViewController] of the profile sections [FlutterListView].
  final FlutterListViewController listController = FlutterListViewController();

  /// Index of the initial profile page section.
  int listInitIndex = 0;

  /// [OngoingCall] used for getting local media devices.
  late final Rx<OngoingCall> call;

  /// [MyUser.name]'s field state.
  late final TextFieldState name;

  /// [MyUser.num]'s copyable state.
  late final TextFieldState num;

  /// [MyUser.chatDirectLink]'s copyable state.
  late final TextFieldState link;

  /// [MyUser.login]'s field state.
  late final TextFieldState login;

  /// Service responsible for [MyUser] management.
  final MyUserService _myUserService;

  /// Settings repository, used to update the [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// [Timer] to set the `RxStatus.empty` status of the [name] field.
  Timer? _nameTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [link] field.
  Timer? _linkTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [login] field.
  Timer? _loginTimer;

  /// Worker to react on [myUser] changes.
  Worker? _myUserWorker;

  /// Worker to react on [RouterState.profileSection] changes.
  Worker? _profileWorker;

  /// Returns current [MyUser] value.
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the current [ApplicationSettings] value.
  Rx<ApplicationSettings?> get settings => _settingsRepo.applicationSettings;

  /// Returns the current background's [Uint8List] value.
  Rx<Uint8List?> get background => _settingsRepo.background;

  /// Returns a list of [MediaDeviceInfo] of all the available devices.
  InputDevices get devices => call.value.devices;

  /// Returns ID of the currently used video device.
  RxnString get camera => call.value.videoDevice;

  /// Returns ID of the currently used microphone device.
  RxnString get mic => call.value.audioDevice;

  /// Returns ID of the currently used output device.
  RxnString get output => call.value.outputDevice;

  @override
  void onInit() {
    listInitIndex = router.profileSection.value?.index ?? 0;

    bool ignoreWorker = false;
    bool ignorePositions = false;

    _profileWorker = ever(
      router.profileSection,
      (ProfileTab? tab) async {
        if (ignoreWorker) {
          ignoreWorker = false;
        } else {
          ignorePositions = true;
          await listController.sliverController.animateToIndex(
            tab?.index ?? 0,
            duration: 200.milliseconds,
            curve: Curves.ease,
          );
          Future.delayed(Duration.zero, () => ignorePositions = false);
        }
      },
    );

    listController.sliverController.onPaintItemPositionsCallback =
        (height, positions) {
      if (positions.isNotEmpty && !ignorePositions) {
        final ProfileTab tab = ProfileTab.values[positions.first.index];
        if (router.profileSection.value != tab) {
          ignoreWorker = true;
          router.profileSection.value = tab;
          Future.delayed(Duration.zero, () => ignoreWorker = false);
        }
      }
    };

    _myUserWorker = ever(
      _myUserService.myUser,
      (MyUser? v) {
        if (!name.focus.hasFocus && !name.changed.value) {
          name.unchecked = v?.name?.val;
        }
        if (!login.focus.hasFocus && !login.changed.value) {
          login.unchecked = v?.login?.val;
        }
        if (!link.focus.hasFocus && !link.changed.value) {
          link.unchecked = v?.chatDirectLink?.slug.val;
        }
      },
    );

    name = TextFieldState(
      text: myUser.value?.name?.val,
      approvable: true,
      onChanged: (s) async {
        s.error.value = null;
        try {
          if (s.text.isNotEmpty) {
            UserName(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        s.error.value = null;
        try {
          if (s.text.isNotEmpty) {
            UserName(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (s.error.value == null) {
          _nameTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService
                .updateUserName(s.text.isNotEmpty ? UserName(s.text) : null);
            s.status.value = RxStatus.empty();
          } catch (e) {
            s.error.value = e.toString();
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    num = TextFieldState(
      text: myUser.value?.num.val.replaceAllMapped(
        RegExp(r'.{4}'),
        (match) => '${match.group(0)} ',
      ),
      editable: false,
    );

    link = TextFieldState(
      text: myUser.value?.chatDirectLink?.slug.val ??
          ChatDirectLinkSlug.generate(10).val,
      approvable: true,
      submitted: myUser.value?.chatDirectLink != null,
      onChanged: (s) {
        s.error.value = null;

        try {
          ChatDirectLinkSlug(s.text);
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

        if (slug == null || slug == myUser.value?.chatDirectLink?.slug) {
          return;
        }

        if (s.error.value == null) {
          _linkTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _myUserService.createChatDirectLink(slug);
            s.status.value = RxStatus.success();
            await Future.delayed(const Duration(seconds: 1));
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

    login = TextFieldState(
      text: myUser.value?.login?.val,
      approvable: true,
      onChanged: (s) async {
        s.error.value = null;

        if (s.text.isEmpty) {
          s.unchecked = myUser.value?.login?.val ?? '';
          s.status.value = RxStatus.empty();
          return;
        }

        try {
          UserLogin(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_login_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        if (s.error.value == null) {
          _loginTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService.updateUserLogin(UserLogin(s.text));
            s.status.value = RxStatus.success();
            _loginTimer = Timer(
              const Duration(milliseconds: 1500),
              () => s.status.value = RxStatus.empty(),
            );
          } on UpdateUserLoginException catch (e) {
            s.error.value = e.toMessage();
            s.status.value = RxStatus.empty();
          } catch (e) {
            s.error.value = 'err_data_transfer'.l10n;
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    if (!PlatformUtils.isMobile) {
      // TODO: This is a really bad hack. We should not create a call here.
      //       Required functionality should be decoupled from the
      //       [OngoingCall] or reimplemented here.
      call = Rx<OngoingCall>(OngoingCall(
        const ChatId('settings'),
        const UserId(''),
        state: OngoingCallState.local,
        mediaSettings: _settingsRepo.mediaSettings.value,
        withAudio: false,
        withVideo: false,
        withScreen: false,
      ));

      call.value.init();
    }

    super.onInit();
  }

  @override
  void onClose() {
    _myUserWorker?.dispose();
    _profileWorker?.dispose();
    call.value.dispose();
    super.onClose();
  }

  /// Removes the currently set [background].
  Future<void> removeBackground() => _settingsRepo.setBackground(null);

  /// Opens an image choose popup and sets the selected file as a [background].
  Future<void> pickBackground() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
      withReadStream: false,
    );

    if (result != null && result.files.isNotEmpty) {
      _settingsRepo.setBackground(result.files.first.bytes);
    }
  }

  /// Deletes the [MyUser.avatar] and [MyUser.callCover].
  Future<void> deleteAvatar() async {
    avatarUpload.value = RxStatus.loading();
    try {
      await _updateAvatar(null);
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }

  /// Uploads an image and sets it as [MyUser.avatar] and [MyUser.callCover].
  Future<void> uploadAvatar() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withReadStream: true,
      );

      if (result != null) {
        avatarUpload.value = RxStatus.loading();

        List<GalleryItemId> deleted = [];

        for (ImageGalleryItem item in myUser.value?.gallery ?? []) {
          deleted.add(item.id);
        }

        for (var e in deleted) {
          _myUserService.deleteGalleryItem(e);
        }

        List<Future<ImageGalleryItem?>> futures = result.files
            .map((e) => NativeFile.fromPlatformFile(e))
            .map((e) => _myUserService.uploadGalleryItem(e))
            .toList();
        ImageGalleryItem? item = (await Future.wait(futures)).firstOrNull;
        if (item != null) {
          _updateAvatar(item.id);
        }
      }
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }

  /// Deletes [myUser]'s account.
  Future<void> deleteAccount() async {
    if (await MessagePopup.alert('alert_are_you_sure'.l10n) == true) {
      await _myUserService.deleteMyUser();
    }
  }

  /// Updates [MyUser.avatar] and [MyUser.callCover] with an [ImageGalleryItem]
  /// with the provided [id].
  ///
  /// If [id] is `null`, then deletes the [MyUser.avatar] and
  /// [MyUser.callCover].
  Future<void> _updateAvatar(GalleryItemId? id) async {
    try {
      await _myUserService.updateAvatar(id);
      await _myUserService.updateCallCover(id);
    } on UpdateUserAvatarException catch (e) {
      MessagePopup.error(e);
    } on UpdateUserCallCoverException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }
}

/// Extension that adds text representation of a [Presence] value.
extension PresenceL10n on Presence {
  /// Returns text representation of a current value.
  String? localizedString() {
    switch (this) {
      case Presence.present:
        return 'label_presence_present'.l10n;
      case Presence.away:
        return 'label_presence_away'.l10n;
      case Presence.hidden:
        return 'label_presence_hidden'.l10n;
      case Presence.artemisUnknown:
        return null;
    }
  }
}

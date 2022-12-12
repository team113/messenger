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
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/ui/page/home/page/my_profile/widget/dropdown.dart';
import '/util/message_popup.dart';
import 'confirm/view.dart';

export 'view.dart';

/// Controller of the `HomeTab.menu` tab.
class MenuTabController extends GetxController {
  MenuTabController(this._authService, this._myUserService);

  /// [MyUser.presence]'s dropdown state.
  late final DropdownFieldState<Presence> presence;

  /// Status of a [uploadAvatar] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [uploadAvatar] is executing.
  /// - `status.isLoading`, meaning [uploadAvatar] is executing.
  final Rx<RxStatus> avatarUpload = Rx(RxStatus.empty());

  /// Auth service used for logout.
  final AuthService _authService;

  /// [Timer] to set the `RxStatus.empty` status of the [avatarStatus].
  Timer? _avatarTimer;

  /// Worker to react on [myUser] changes.
  Worker? _worker;

  /// Service managing [MyUser].
  final MyUserService _myUserService;

  /// Current [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  onInit() {
    _worker = ever(
      _myUserService.myUser,
      (MyUser? v) {
        if (!presence.focus.hasFocus) {
          presence.unchecked = v?.presence;
        }
      },
    );

    super.onInit();
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }

  /// Determines whether the [logout] action may be invoked or not.
  ///
  /// Shows a confirmation popup if there's any ongoing calls.
  Future<bool> confirmLogout() async {
    // TODO: [MyUserService.myUser] might still be `null` here.
    if (await ConfirmLogoutView.show(router.context!) != true) {
      return false;
    }

    return true;
  }

  /// Logs out the current session and go to the [Routes.auth] page.
  Future<String> logout() => _authService.logout();

  /// Sets the [MyUser.presence].
  Future<void> setPresence(Presence presence) async {
    await _myUserService.updateUserPresence(presence);
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
    } on DioError catch (e) {
      if (e.response?.data != null) {
        MessagePopup.error(e.response?.data);
      } else {
        MessagePopup.error(e);
      }

      rethrow;
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }

  /// Updates [MyUser.avatar] and [MyUser.callCover] with an [ImageGalleryItem]
  /// with the provided [id].
  ///
  /// If [id] is `null`, then deletes the [MyUser.avatar] and
  /// [MyUser.callCover].
  Future<void> _updateAvatar(GalleryItemId? id) async {
    try {
      _avatarTimer?.cancel();
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

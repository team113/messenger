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

import 'dart:math';

import 'package:get/get.dart';

import '/domain/model/crop_area.dart';
import '/domain/model/native_file.dart';
import '/domain/service/my_user.dart';
import '/provider/gql/exceptions.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Controller of the [CropAvatarView].
class CropAvatarController extends GetxController {
  CropAvatarController(
    this._myUserService, {
    required this.imageWidth,
    required this.imageHeight,
  });

  /// Service responsible for [MyUser] management.
  final MyUserService _myUserService;

  /// Original image width.
  final double imageWidth;

  /// Original image height.
  final double imageHeight;

  /// Status of an [uploadAvatar] or [deleteAvatar] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [uploadAvatar]/[deleteAvatar] is executing.
  /// - `status.isLoading`, meaning [uploadAvatar]/[deleteAvatar] is executing.
  final Rx<RxStatus> avatarUpload = Rx(RxStatus.empty());

  /// Width of resizable crop area.
  final RxDouble cropAreaWidth = RxDouble(100);

  /// Height of resizable crop area.
  final RxDouble cropAreaHeight = RxDouble(100);

  /// Offset of crop area along x axis.
  final RxDouble cropAreaOffsetX = RxDouble(0);

  /// Offset of crop area along y axis.
  final RxDouble cropAreaOffsetY = RxDouble(0);

  /// Rotate angle of image.
  final RxDouble rotateAngle = RxDouble(0);

  final Rx<Angle> angle = Rx<Angle>(Angle.deg0);

  /// Updates [MyUser.avatar] and [MyUser.callCover] with the provided [file].
  ///
  /// If [file] is `null`, then deletes the [MyUser.avatar] and
  /// [MyUser.callCover].
  Future<void> _updateAvatar(
    NativeFile? file, {
    CropArea? crop,
  }) async {
    print('_updateAvatar');
    try {
      await Future.wait([
        _myUserService.updateAvatar(file, crop: crop),
        _myUserService.updateCallCover(file, crop: crop)
      ]);
    } on UpdateUserAvatarException catch (e) {
      MessagePopup.error(e);
    } on UpdateUserCallCoverException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  @override
  void onInit() {
    cropAreaWidth.value = imageWidth > imageHeight ? imageHeight : imageWidth;
    cropAreaHeight.value = imageHeight > imageWidth ? imageWidth : imageHeight;

    // TODO: calculate offset.
    //cropAreaOffsetX.value = imageWidth / 2;
    //cropAreaOffsetY.value = imageHeight / 2;
    super.onInit();
  }

  static const deg90 = pi / 2;
  static const deg180 = pi;
  static const deg270 = 3 * pi / 2;

  /// Rotates image clockwise.
  void onRotateCw() {
    rotateAngle.value = rotateAngle.value += pi / 2;
    if (rotateAngle.value == 2 * pi) {
      rotateAngle.value = 0;
    }

    switch (rotateAngle.value) {
      case (0):
        angle.value = Angle.deg0;
      case (deg90):
        angle.value = Angle.deg90;
      case (deg180):
        angle.value = Angle.deg180;
      case (deg270):
        angle.value = Angle.deg270;
    }

    //angle.value = Angle.;
  }

  /// Rotates image counterclockwise.
  void onRotateCcw() {
    rotateAngle.value -= pi / 2;

    if (rotateAngle.value == -(2 * pi)) {
      rotateAngle.value = 0;
    }
    switch (rotateAngle.value) {
      case (0):
        angle.value = Angle.deg0;
      case (-(deg90)):
        angle.value = Angle.deg270;
      case (-(deg180)):
        angle.value = Angle.deg180;
      case (-(deg270)):
        angle.value = Angle.deg90;
    }
  }

  /// Uploads an image and sets it as [MyUser.avatar] and [MyUser.callCover].
  Future<void> uploadAvatar(imageFile, imageBytes) async {
    try {
      // XFile? imageFile =
      //     await ImagePicker().pickImage(source: ImageSource.gallery);
      //Uint8List imageBytes = await imageFile!.readAsBytes();
      final CropPoint bottomRight = CropPoint(
        x: cropAreaWidth.value.toInt() + cropAreaOffsetX.value.toInt(),
        y: cropAreaHeight.value.toInt() + cropAreaOffsetY.value.toInt(),
      );
      final CropPoint topLeft = CropPoint(
        x: cropAreaOffsetX.value.toInt(),
        y: cropAreaOffsetY.value.toInt(),
      );

      final CropArea crop = CropArea(
        bottomRight: bottomRight,
        topLeft: topLeft,
        angle: angle.value,
      );

      avatarUpload.value = RxStatus.loading();
      await _updateAvatar(
        imageFile,
        crop: crop,
      );
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }
}

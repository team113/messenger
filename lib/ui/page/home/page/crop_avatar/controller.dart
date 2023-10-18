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

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '/api/backend/schema.dart' show Angle, CropAreaInput, PointInput;
import '/domain/model/native_file.dart';

export 'view.dart';

/// Controller of the [CropAvatarView].
class CropAvatarController extends GetxController {
  CropAvatarController({
    required this.imageWidth,
    required this.imageHeight,
    required this.updateAvatar,
  });

  /// Uploads an image and sets it as [MyUser.avatar] and [MyUser.callCover].
  final Function updateAvatar;

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

  @override
  void onInit() {
    cropAreaWidth.value = imageWidth > imageHeight ? imageHeight : imageWidth;
    cropAreaHeight.value = imageHeight > imageWidth ? imageWidth : imageHeight;

    // TODO: calculate offset.
    //cropAreaOffsetX.value = imageWidth / 2;
    //cropAreaOffsetY.value = imageHeight / 2;
    super.onInit();
  }

  /// Rotates image clockwise.
  void onRotateCw() {
    rotateAngle.value = rotateAngle.value += pi / 2;
    switch(rotateAngle.value) {
      case(0): angle.value = Angle.deg0;
      case(90): angle.value = Angle.deg90;
      case(180): angle.value = Angle.deg180;
      case(270): angle.value = Angle.deg270;
    }
    
    //angle.value = Angle.;
  }

  /// Rotates image counterclockwise.
  void onRotateCcw() {
    rotateAngle.value -= pi / 2;
    switch(rotateAngle.value) {
      case(0): angle.value = Angle.deg0;
      case(90): angle.value = Angle.deg90;
      case(180): angle.value = Angle.deg180;
      case(270): angle.value = Angle.deg270;
    }
  }

  /// Uploads an image and sets it as [MyUser.avatar] and [MyUser.callCover].
  Future<void> uploadAvatar(imageFile, imageBytes) async {
    try {
      // XFile? imageFile =
      //     await ImagePicker().pickImage(source: ImageSource.gallery);
      //Uint8List imageBytes = await imageFile!.readAsBytes();
      final PointInput bottomRight = PointInput(
        x: cropAreaWidth.value.toInt() + cropAreaOffsetX.value.toInt(),
        y: cropAreaHeight.value.toInt() + cropAreaOffsetY.value.toInt(),
      );
      final PointInput topLeft = PointInput(
        x: cropAreaOffsetX.value.toInt(),
        y: cropAreaOffsetY.value.toInt(),
      );

      final CropAreaInput crop = CropAreaInput(
        bottomRight: bottomRight,
        topLeft: topLeft,
        angle: angle.value,
      );
      print(crop);

      avatarUpload.value = RxStatus.loading();
      await updateAvatar(
        NativeFile.fromXFile(imageFile!, imageBytes),
        crop,
      );
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }
}

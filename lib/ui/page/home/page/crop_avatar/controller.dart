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

export 'view.dart';

/// Controller of the [CropAvatarView].
class CropAvatarController extends GetxController {
  CropAvatarController({required this.imageWidth, required this.imageHeight});

  /// Original image width.
  final double imageWidth;

  /// Original image height.
  final double imageHeight;

  @override
  void onInit() {
    cropAreaWidth.value = imageWidth > imageHeight ? imageHeight : imageWidth;
    cropAreaHeight.value = imageHeight > imageWidth ? imageWidth : imageHeight;

    super.onInit();
  }

  /// .
  final RxDouble cropAreaWidth = RxDouble(100);

  /// .
  final RxDouble cropAreaHeight = RxDouble(100);

  /// .
  final RxDouble cropAreaOffsetX = RxDouble(0);

  /// .
  final RxDouble cropAreaOffsetY = RxDouble(0);

  /// .
  final RxDouble rotateAngle = RxDouble(0);

  void onRotateCw() {
    rotateAngle.value = rotateAngle.value += pi / 2;
  }

  void onRotateCcw() {
    rotateAngle.value -= pi / 2;
  }
}

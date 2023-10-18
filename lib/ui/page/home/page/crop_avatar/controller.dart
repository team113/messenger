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
  CropAvatarController();

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

  onRotateCw() {
    rotateAngle.value = rotateAngle.value += pi / 2;
  }

  onRotateCcw() {
    rotateAngle.value -= pi / 2;
  }
}

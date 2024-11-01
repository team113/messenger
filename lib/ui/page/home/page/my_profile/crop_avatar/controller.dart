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

import 'dart:typed_data';
import 'dart:ui';

import 'package:get/get.dart';

import 'widget/image_cropper/enums.dart';
import 'widget/image_cropper/widget.dart';

/// Controller for an [ImageCropper].
///
/// Provides methods for rotating image and adjusting crop rectangle.
class CropController extends GetxController {
  CropController(this.image);

  /// [Uint8List] of the image to crop.
  final Uint8List image;

  /// Crop rectangle coordinates for [image].
  ///
  /// Values should be normalized between 0 and 1.
  final Rx<Rect> crop = Rx(const Rect.fromLTWH(0, 0, 1, 1));

  /// Current image rotation.
  final Rx<CropRotation> rotation = Rx(CropRotation.up);

  /// [Size] of the [image].
  final Rx<Size> dimensions = Rx(const Size(0, 0));

  /// Returns the aspect ratio of [image].
  double get aspect => dimensions.value.aspectRatio;

  /// Returns the [Size] of the [image].
  Size get size => dimensions.value;

  /// Returns the [crop] rectangle of [image] in pixels.
  Rect get real {
    final isSideways = rotation.value.isSideways;
    final width = isSideways ? size.height : size.width;
    final height = isSideways ? size.width : size.height;
    return crop.value.multiply(Size(width, height));
  }

  /// Sets the [rect] in pixels to be [crop] and adjust [crop] to fit new size.
  set real(Rect rect) {
    crop.value = _adjustRatio(rect.divide(size), aspect);
  }

  @override
  void onInit() {
    _initializeBitmap();
    super.onInit();
  }

  /// Rotates image 90 degrees right.
  void rotateRight() => _rotate(false);

  /// Rotates image 90 degrees left.
  void rotateLeft() => _rotate(true);

  /// Rotates image 90 degrees based on [left].
  void _rotate(bool left) {
    final CropRotation newRotation =
        left ? rotation.value.rotateLeft : rotation.value.rotateRight;

    final Offset newCenter = left
        ? Offset(crop.value.center.dy, 1 - crop.value.center.dx)
        : Offset(1 - crop.value.center.dy, crop.value.center.dx);

    crop.value = _adjustRatio(
      Rect.fromCenter(
        center: newCenter,
        width: crop.value.height,
        height: crop.value.width,
      ),
      aspect,
      rotation: newRotation,
    );

    rotation.value = newRotation;
  }

  /// Adjusts [crop] rectangle to fit the specified aspect ratio.
  Rect _adjustRatio(
    Rect crop,
    double? aspectRatio, {
    CropRotation? rotation,
  }) {
    if (aspectRatio == null) {
      return crop;
    }

    final bool justRotated = rotation != null;
    rotation ??= this.rotation.value;

    final bitmapWidth = rotation.isSideways ? size.height : size.width;
    final bitmapHeight = rotation.isSideways ? size.width : size.height;
    if (justRotated) {
      const Offset center = Offset(.5, .5);

      final double width = bitmapWidth;
      final double height = bitmapHeight;

      if (width / height > aspectRatio) {
        final double w = height * aspectRatio / bitmapWidth;
        return Rect.fromCenter(center: center, width: w, height: 1);
      }

      final double h = width / aspectRatio / bitmapHeight;
      return Rect.fromCenter(center: center, width: 1, height: h);
    }

    final double width = crop.width * bitmapWidth;
    final double height = crop.height * bitmapHeight;

    if (width / height > aspectRatio) {
      final double w = height * aspectRatio / bitmapWidth;
      return Rect.fromLTWH(crop.center.dx - w / 2, crop.top, w, crop.height);
    } else {
      final double h = width / aspectRatio / bitmapHeight;
      return Rect.fromLTWH(crop.left, crop.center.dy - h / 2, crop.width, h);
    }
  }

  /// Resolves image and initializes [dimensions].
  void _initializeBitmap() async {
    final Codec decoded = await instantiateImageCodec(image);
    final FrameInfo frame = await decoded.getNextFrame();
    dimensions.value = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    crop.value = _adjustRatio(crop.value, aspect);
  }
}

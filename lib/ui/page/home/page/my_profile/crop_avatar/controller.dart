// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter_svg/flutter_svg.dart';
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

  /// [PictureInfo] of the [image] being an SVG.
  PictureInfo? svg;

  /// Returns the aspect ratio of [image].
  double get aspect => dimensions.value.aspectRatio;

  /// Returns the [Size] of the [image].
  Size get size => dimensions.value;

  /// Returns the [crop] rectangle of [image] in pixels.
  Rect get real {
    return crop.value.multiply(size).rotated(rotation.value, size);
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
    rotation.value = left
        ? rotation.value.rotateLeft
        : rotation.value.rotateRight;
  }

  /// Resolves image and initializes [dimensions].
  void _initializeBitmap() async {
    try {
      final Codec decoded = await instantiateImageCodec(image);
      final FrameInfo frame = await decoded.getNextFrame();
      dimensions.value = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    } catch (rasterError, rasterStack) {
      try {
        final PictureInfo picture = await vg.loadPicture(
          SvgStringLoader(String.fromCharCodes(image)),
          null,
        );
        dimensions.value = picture.size;
        svg = picture;
      } catch (vectorError, vectorStack) {
        throw CombinedImageDecodeException(
          rasterError: rasterError,
          rasterStack: rasterStack,
          vectorError: vectorError,
          vectorStack: vectorStack,
        );
      }
    }
  }
}

/// Exception thrown when both raster and SVG image decoding fails.
class CombinedImageDecodeException implements Exception {
  const CombinedImageDecodeException({
    required this.rasterError,
    required this.rasterStack,
    required this.vectorError,
    required this.vectorStack,
  });

  /// [Exception] of the [instantiateImageCodec] error happened.
  final Object rasterError;

  /// [StackTrace] of the [instantiateImageCodec] error happened.
  final StackTrace rasterStack;

  /// [Exception] of the [VectorGraphicUtilities.loadPicture] error happened.
  final Object vectorError;

  /// [StackTrace] of the [VectorGraphicUtilities.loadPicture] error happened.
  final StackTrace vectorStack;

  @override
  String toString() {
    return 'CombinedImageDecodeException:\n'
        '--- Raster error ---\n$rasterError\n'
        '--- Vector error ---\n$vectorError';
  }
}

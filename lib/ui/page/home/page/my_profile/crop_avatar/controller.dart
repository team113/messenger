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
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'widget/image_cropper/enums.dart';

/// Controller for cropping image.
/// It provides methods for rotating image and adjusting crop rectangle.
class CropController extends GetxController {
  CropController({
    required this.image,
    double? aspectRatio,
    Rect defaultCrop = const Rect.fromLTWH(0, 0, 1, 1),
    CropRotation rotation = CropRotation.up,
  })  : assert(aspectRatio != 0, 'aspectRatio cannot be zero'),
        assert(defaultCrop.left >= 0 && defaultCrop.left <= 1,
            'left should be 0..1'),
        assert(defaultCrop.right >= 0 && defaultCrop.right <= 1,
            'right should be 0..1'),
        assert(
            defaultCrop.top >= 0 && defaultCrop.top <= 1, 'top should be 0..1'),
        assert(defaultCrop.bottom >= 0 && defaultCrop.bottom <= 1,
            'bottom should be 0..1'),
        assert(defaultCrop.left < defaultCrop.right,
            'left must be less than right'),
        assert(defaultCrop.top < defaultCrop.bottom,
            'top must be less than bottom'),
        _aspectRatio = Rx<double?>(aspectRatio),
        rotation = rotation.obs,
        crop = defaultCrop.obs;

  CropController.fromValue(CropController value)
      : image = value.image,
        crop = value.crop,
        rotation = value.rotation,
        bitmap = value.bitmap,
        _aspectRatio = value.aspectRatio.obs;

  /// Image to be cropped.
  final Image image;

  /// Crop rectangle coordinates for [image].
  /// Values are normalized between 0 and 1.
  final Rx<Rect> crop;

  /// Current image rotation.
  final Rx<CropRotation> rotation;

  /// Bitmap representation of image.
  /// Initialized in [onInit] method.
  ui.Image? bitmap;

  /// Listens to [crop] value changes and adjusts [_aspectRatio].
  late final Worker _worker;

  /// Current aspect ratio of image.
  final Rx<double?> _aspectRatio;

  /// Get current aspect ratio.
  double? get aspectRatio => _aspectRatio.value;

  /// Sets [_aspectRatio] and adjusts [crop] to fit new aspect ratio.
  set aspectRatio(double? newAspectRatio) {
    _aspectRatio.value = newAspectRatio;
    if (newAspectRatio != null) {
      crop.value = _adjustRatio(crop.value, newAspectRatio);
    }
  }

  /// Current crop rectangle of image (in pixels).
  /// For sideways rotation, width and height are interchanged.
  /// See also: [crop], which represents same rectangle in percentage.
  Rect get cropSize {
    final isSideways = rotation.value.isSideways;
    final width = isSideways ? bitmapSize.height : bitmapSize.width;
    final height = isSideways ? bitmapSize.width : bitmapSize.height;
    return crop.value.multiply(Size(width, height));
  }

  /// Accepts [newCropSize] in pixels and adjust [crop] to fit new size.
  set cropSize(Rect newCropSize) {
    crop.value = _adjustRatio(newCropSize.divide(bitmapSize), aspectRatio);
  }

  /// Returns image dimensions
  Size get bitmapSize =>
      Size(bitmap!.width.toDouble(), bitmap!.height.toDouble());

  /// Returns true if [bitmap] is initialized.
  @override
  bool get initialized {
    return super.initialized && bitmap != null;
  }

  @override
  void onInit() {
    super.onInit();

    // Adjusts the crop rectangle whenever the crop value changes.
    _worker = ever(crop, (crop) => _adjustRatio(crop, aspectRatio));

    // Initializes the bitmap representation of the image.
    _initializeBitmap();
  }

  @override
  void dispose() {
    super.dispose();
    _worker.dispose();
  }

  /// Rotates the image 90 degrees to the right.
  void rotateRight() => _rotate(left: false);

  /// Rotates the image 90 degrees to the left.
  void rotateLeft() => _rotate(left: true);

  /// Rotates the image 90 degrees to the left or right.
  void _rotate({required final bool left}) {
    final CropRotation newRotation =
        left ? rotation.value.rotateLeft : rotation.value.rotateRight;
    final Offset newCenter = left
        ? Offset(crop.value.center.dy, 1 - crop.value.center.dx)
        : Offset(1 - crop.value.center.dy, crop.value.center.dx);
    _aspectRatio.value = aspectRatio;
    crop.value = _adjustRatio(
      Rect.fromCenter(
        center: newCenter,
        width: crop.value.height,
        height: crop.value.width,
      ),
      aspectRatio,
      rotation: newRotation,
    );
    rotation.value = newRotation;
    update();
  }

  /// Adjusts the crop rectangle to fit the specified aspect ratio.
  ///
  /// If the aspect ratio is null, the crop rectangle is returned as is.
  /// If the image has just been rotated, the crop rectangle is adjusted to fit the largest centered crop.
  /// Otherwise, the crop rectangle is adjusted to fit the specified aspect ratio.
  ///
  /// Returns the adjusted crop rectangle.
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
    final bitmapWidth =
        rotation.isSideways ? bitmapSize.height : bitmapSize.width;
    final bitmapHeight =
        rotation.isSideways ? bitmapSize.width : bitmapSize.height;
    if (justRotated) {
      // we've just rotated: in that case, biggest centered crop.
      const center = Offset(.5, .5);
      final width = bitmapWidth;
      final height = bitmapHeight;
      if (width / height > aspectRatio) {
        final w = height * aspectRatio / bitmapWidth;
        return Rect.fromCenter(center: center, width: w, height: 1);
      }
      final h = width / aspectRatio / bitmapHeight;
      return Rect.fromCenter(center: center, width: 1, height: h);
    }
    final width = crop.width * bitmapWidth;
    final height = crop.height * bitmapHeight;
    if (width / height > aspectRatio) {
      final w = height * aspectRatio / bitmapWidth;
      return Rect.fromLTWH(crop.center.dx - w / 2, crop.top, w, crop.height);
    } else {
      final h = width / aspectRatio / bitmapHeight;
      return Rect.fromLTWH(crop.left, crop.center.dy - h / 2, crop.width, h);
    }
  }

  /// Initializes the bitmap representation of the image.
  ///
  /// This method resolves the image and retrieves its dimensions.
  /// Once the image is resolved, the bitmap is set and the aspect ratio is updated.
  void _initializeBitmap() async {
    final completer = Completer<ImageInfo>();
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (info, _) {
          return completer.complete(info);
        },
      ),
    );

    final imageInfo = await completer.future;
    bitmap = imageInfo.image;
    aspectRatio = aspectRatio;
    update();
  }
}

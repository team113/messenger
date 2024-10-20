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

/// Controller for [ImageCropper] widget. It allows to control the crop rectangle and rotation.
/// It also provides the ability to rotate the image.
class CropController extends GetxController {
  final Image image;
  final Rx<double?> _aspectRatio;
  Rx<Rect> crop;
  Rx<CropRotation> rotation;

  @override
  bool get initialized {
    return super.initialized && bitmap != null;
  }

  ui.Image? bitmap;

  Size get bitmapSize =>
      Size(bitmap!.width.toDouble(), bitmap!.height.toDouble());

  @override
  onInit() async {
    super.onInit();
    Completer<ImageInfo> completer = Completer<ImageInfo>();
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          completer.complete(info);
        },
      ),
    );
    ImageInfo imageInfo = await completer.future;
    bitmap = imageInfo.image;
    aspectRatio = aspectRatio;
    update();
  }

  /// A controller for a [CropImage] widget.
  ///
  /// You can provide the required [aspectRatio] and the initial [defaultCrop].
  /// If [aspectRatio] is specified, the [defaultCrop] rect will be adjusted automatically.
  ///
  /// Remember to [dispose] of the [CropController] when it's no longer needed.
  /// This will ensure we discard any resources used by the object.

  /// Creates a controller for a [CropImage] widget from an initial [CropControllerValue].
  CropController({
    required this.image,
    double aspectRatio = 1,
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
        _aspectRatio = RxDouble(aspectRatio),
        rotation = rotation.obs,
        crop = defaultCrop.obs;

  CropController.fromValue(CropController value)
      : image = value.image,
        crop = value.crop,
        rotation = value.rotation,
        bitmap = value.bitmap,
        _aspectRatio = value.aspectRatio.obs;

  /// Aspect ratio of the image (width / height).
  ///
  /// The [crop] rectangle will be adjusted to fit this ratio.
  /// Pass null for free selection clipping (aspect ratio not enforced).
  double? get aspectRatio => _aspectRatio.value;

  set aspectRatio(double? newAspectRatio) {
    if (newAspectRatio != null) {
      _aspectRatio.value = newAspectRatio;
      crop.value = _adjustRatio(crop.value, newAspectRatio);
    } else {
      _aspectRatio.value = null;
    }
  }

  /// Current crop rectangle of the image (percentage).
  ///
  /// [left] and [right] are normalized between 0 and 1 (full width).
  /// [top] and [bottom] are normalized between 0 and 1 (full height).
  ///
  /// If the [aspectRatio] was specified, the rectangle will be adjusted to fit that ratio.
  ///
  /// See also:
  ///
  ///  * [cropSize], which represents the same rectangle in pixels.
  // Rx<Rect> get crop => _crop;
  //
  // set crop(Rect newCrop) {
  //   _crop.value = _adjustRatio(crop, aspectRatio);
  // }

  void rotateRight() => _rotate(left: false);

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

  /// Current crop rectangle of the image (pixels).
  ///
  /// [left], [right], [top] and [bottom] are in pixels.
  ///
  /// If the [aspectRatio] was specified, the rectangle will be adjusted to fit that ratio.
  ///
  /// See also:
  ///
  ///  * [crop], which represents the same rectangle in percentage.
  Rect get cropSize {
    final isSideways = rotation.value.isSideways;
    final width = isSideways ? bitmapSize.height : bitmapSize.width;
    final height = isSideways ? bitmapSize.width : bitmapSize.height;
    return crop.value.multiply(Size(width, height));
  }

  set cropSize(Rect newCropSize) {
    crop.value = _adjustRatio(newCropSize.divide(bitmapSize), aspectRatio);
  }

  /// Adjusts the crop rectangle to fit the specified aspect ratio.
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
}

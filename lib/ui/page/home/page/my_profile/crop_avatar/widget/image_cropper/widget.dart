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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller.dart';
import 'enums.dart';
import 'utils.dart';

/// Widget for cropping image.
/// It displays image with crop rectangle that can be moved and resized.
class ImageCropper extends StatefulWidget {
  /// Controller for managing crop area and notifying listeners of changes.
  final CropController controller;

  /// [CropGrid] scrim (outside area overlay) color.
  /// Defaults to 54% black.
  final Color scrimColor;

  /// Minimum pixel size crop [Rect] can be shrunk to.
  /// Defaults to `100`.
  final double minimumImageSize;

  @override
  State<ImageCropper> createState() => _ImageCropperState();

  const ImageCropper({
    super.key,
    required this.controller,
    this.scrimColor = Colors.black54,
    this.minimumImageSize = 100,
  }) : assert(minimumImageSize > 0,
            'minimumImageSize should be greater than zero.');
}

class _ImageCropperState extends State<ImageCropper> {
  /// Manages crop area and notifying listeners of changes.
  late CropController controller;

  /// [Size] of displayed image.
  /// Updated by [CropGrid] on layout's [onSize] callback.
  Size size = Size.zero;

  /// Current crop handle point being interacted with, if any.
  CropHandlePoint? cropHandlePoint;

  /// [Map] of crop handle positions.
  /// Used to determine which part of crop rectangle is being interacted with.
  Map<CropHandle, Offset> get cropHandlePositions => <CropHandle, Offset>{
        CropHandle.upperLeft:
            controller.crop.value.topLeft.scale(size.width, size.height),
        CropHandle.upperRight:
            controller.crop.value.topRight.scale(size.width, size.height),
        CropHandle.lowerRight:
            controller.crop.value.bottomRight.scale(size.width, size.height),
        CropHandle.lowerLeft:
            controller.crop.value.bottomLeft.scale(size.width, size.height),
      };

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (!controller.initialized) {
            return const CircularProgressIndicator.adaptive();
          }
          final double maxWidth = constraints.maxWidth;
          final double maxHeight = constraints.maxHeight;
          final double width = _getWidth(maxWidth, maxHeight);
          final double height = _getHeight(maxWidth, maxHeight);
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Obx(() {
                return SizedBox(
                  width: width,
                  height: height,
                  child: CustomPaint(
                    painter: RotatedImagePainter(
                      controller.bitmap!,
                      controller.rotation.value,
                    ),
                  ),
                );
              }),
              Obx(() {
                return SizedBox(
                  width: width,
                  height: height,
                  child: GestureDetector(
                    onPanStart: onPanStart,
                    onPanUpdate: onPanUpdate,
                    onPanEnd: onPanEnd,
                    child: CropGrid(
                      crop: controller.crop.value,
                      scrimColor: widget.scrimColor,
                      isMoving: cropHandlePoint != null,
                      onSize: (size) {
                        this.size = size;
                      },
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  /// Updates [cropHandlePoint] based on user's touch point.
  void onPanStart(DragStartDetails details) {
    if (cropHandlePoint == null) {
      final type = hitTest(details.localPosition);
      if (type != CropHandle.none) {
        final Offset basePoint = cropHandlePositions[
            (type == CropHandle.move) ? CropHandle.upperLeft : type]!;
        setState(() {
          cropHandlePoint =
              CropHandlePoint(type, details.localPosition - basePoint);
        });
      }
    }
  }

  /// Resizes or moves crop rectangle bases on [DragUpdateDetails] provided.
  void onPanUpdate(DragUpdateDetails details) {
    if (cropHandlePoint != null) {
      final offset = details.localPosition - cropHandlePoint!.offset;
      if (cropHandlePoint!.type == CropHandle.move) {
        moveArea(offset);
      } else {
        moveCorner(cropHandlePoint!.type, offset);
      }
    }
  }

  /// Resets [cropHandlePoint] when pan gesture ends.
  void onPanEnd(DragEndDetails details) {
    setState(() {
      cropHandlePoint = null;
    });
  }

  /// Returns [CropHandle] that is being interacted with based on [point].
  CropHandle hitTest(Offset point) {
    for (final gridCorner in cropHandlePositions.entries) {
      final area = Rect.fromCenter(
        center: gridCorner.value,
        width: 50,
        height: 50,
      );
      if (area.contains(point)) {
        return gridCorner.key;
      }
    }
    final area = Rect.fromPoints(
      cropHandlePositions[CropHandle.upperLeft]!,
      cropHandlePositions[CropHandle.lowerRight]!,
    );
    return area.contains(point) ? CropHandle.move : CropHandle.none;
  }

  /// Moves the crop rectangle based on the [cropHandlePoint].
  void moveArea(Offset point) {
    final crop = controller.crop.value.multiply(size);
    controller.crop.value = Rect.fromLTWH(
      point.dx.clamp(0, size.width - crop.width),
      point.dy.clamp(0, size.height - crop.height),
      crop.width,
      crop.height,
    ).divide(size);
  }

  /// Resizes the crop rectangle by moving corner based on [type] and [point].
  void moveCorner(CropHandle type, Offset point) {
    final Rect crop = controller.crop.value.multiply(size);
    double left = crop.left;
    double top = crop.top;
    double right = crop.right;
    double bottom = crop.bottom;
    double minX, maxX;
    double minY, maxY;

    switch (type) {
      case CropHandle.upperLeft:
        minX = 0;
        maxX = right - widget.minimumImageSize;
        if (minX <= maxX) {
          left = point.dx.clamp(minX, maxX);
        }
        minY = 0;
        maxY = bottom - widget.minimumImageSize;
        if (minY <= maxY) {
          top = point.dy.clamp(minY, maxY);
        }
        break;
      case CropHandle.upperRight:
        minX = left + widget.minimumImageSize;
        maxX = size.width;
        if (minX <= maxX) {
          right = point.dx.clamp(minX, maxX);
        }
        minY = 0;
        maxY = bottom - widget.minimumImageSize;
        if (minY <= maxY) {
          top = point.dy.clamp(minY, maxY);
        }
        break;
      case CropHandle.lowerRight:
        minX = left + widget.minimumImageSize;
        maxX = size.width;
        if (minX <= maxX) {
          right = point.dx.clamp(minX, maxX);
        }
        minY = top + widget.minimumImageSize;
        maxY = size.height;
        if (minY <= maxY) {
          bottom = point.dy.clamp(minY, maxY);
        }
        break;
      case CropHandle.lowerLeft:
        minX = 0;
        maxX = right - widget.minimumImageSize;
        if (minX <= maxX) {
          left = point.dx.clamp(minX, maxX);
        }
        minY = top + widget.minimumImageSize;
        maxY = size.height;
        if (minY <= maxY) {
          bottom = point.dy.clamp(minY, maxY);
        }
        break;
      default:
        assert(false);
    }

    if (controller.aspectRatio != null) {
      final width = right - left;
      final height = bottom - top;
      if (width / height > controller.aspectRatio!) {
        switch (type) {
          case CropHandle.upperLeft:
          case CropHandle.lowerLeft:
            left = right - height * controller.aspectRatio!;
            break;
          case CropHandle.upperRight:
          case CropHandle.lowerRight:
            right = left + height * controller.aspectRatio!;
            break;
          default:
            assert(false);
        }
      } else {
        switch (type) {
          case CropHandle.upperLeft:
          case CropHandle.upperRight:
            top = bottom - width / controller.aspectRatio!;
            break;
          case CropHandle.lowerRight:
          case CropHandle.lowerLeft:
            bottom = top + width / controller.aspectRatio!;
            break;
          default:
            assert(false);
        }
      }
    }

    controller.crop.value =
        Rect.fromLTRB(left, top, right, bottom).divide(size);
  }

  /// Returns the ratio of the image's width to height.
  double _getImageRatio() =>
      controller.bitmapSize.width / controller.bitmapSize.height;

  /// Returns the width of the image based on the rotation, maximum width and maximum height constraints.
  double _getWidth(final double maxWidth, final double maxHeight) {
    double imageRatio = _getImageRatio();
    final screenRatio = maxWidth / maxHeight;
    if (controller.rotation.value.isSideways) {
      imageRatio = 1 / imageRatio;
    }
    if (imageRatio > screenRatio) {
      return maxWidth;
    }
    return maxHeight * imageRatio;
  }

  /// Returns the height of the image based on the rotation, maximum width and maximum height constraints.
  double _getHeight(final double maxWidth, final double maxHeight) {
    double imageRatio = _getImageRatio();
    final screenRatio = maxWidth / maxHeight;
    if (controller.rotation.value.isSideways) {
      imageRatio = 1 / imageRatio;
    }
    if (imageRatio < screenRatio) {
      return maxHeight;
    }
    return maxWidth / imageRatio;
  }
}

/// Crop Grid with invisible border, for better touch detection.
class CropGrid extends StatelessWidget {
  /// Crop [Rect] to be displayed
  final Rect crop;

  /// [Color] of scrim (outside area overlay).
  final Color scrimColor;

  /// Whether crop area is being moved.
  final bool isMoving;

  /// Callback to updated [Size] of displayed image.
  final ValueChanged<Size> onSize;

  const CropGrid({
    super.key,
    required this.crop,
    required this.scrimColor,
    required this.isMoving,
    required this.onSize,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: CropGridPainter(this),
      ),
    );
  }
}

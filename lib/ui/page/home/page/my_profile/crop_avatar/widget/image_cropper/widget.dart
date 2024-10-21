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

/// Displays [image] with a [CropGrid] on top to select crop area as [Rect].
/// [CropController] controls the crop values being applied and notifies when the crop changes.
class ImageCropper extends StatefulWidget {
  /// If null, this widget will create its own [CropController]. If you want to specify initial values of
  /// [aspectRatio] or [defaultCrop], you need to use your own [CropController].
  /// Otherwise, [aspectRatio] will not be enforced and the [defaultCrop] will be the full image.
  final CropController controller;

  /// The crop grid color of the outer lines.
  ///
  /// Defaults to 70% white.
  final Color gridColor;

  /// The crop grid color of the inner lines.
  ///
  /// Defaults to `gridColor`.
  final Color gridInnerColor;

  /// The crop grid color of the corner lines.
  ///
  /// Defaults to `gridColor`.
  final Color gridCornerColor;

  /// The size of the touch area.
  ///
  /// Defaults to 50.
  final double touchSize;

  /// The size of the corner of the crop grid.
  ///
  /// Defaults to 25.
  final double gridCornerSize;

  /// Whether to display the corners.
  ///
  /// Defaults to true.
  final bool showCorners;

  /// The width of the crop grid thin lines.
  ///
  /// Defaults to 2.
  final double gridThinWidth;

  /// The width of the crop grid thick lines.
  ///
  /// Defaults to 5.
  final double gridThickWidth;

  /// The crop grid scrim (outside area overlay) color.
  ///
  /// Defaults to 54% black.
  final Color scrimColor;

  /// The minimum pixel size the crop rectangle can be shrunk to.
  ///
  /// Defaults to 100.
  final double minimumImageSize;

  const ImageCropper({
    super.key,
    required this.controller,
    this.gridColor = Colors.white70,
    Color? gridInnerColor,
    Color? gridCornerColor,
    this.touchSize = 50,
    this.gridCornerSize = 30,
    this.showCorners = true,
    this.gridThinWidth = 2,
    this.gridThickWidth = 5,
    this.scrimColor = Colors.black54,
    this.minimumImageSize = 100,
  })  : gridInnerColor = gridInnerColor ?? gridColor,
        gridCornerColor = gridCornerColor ?? gridColor,
        assert(gridCornerSize > 0, 'gridCornerSize cannot be zero'),
        assert(touchSize > 0, 'touchSize cannot be zero'),
        assert(gridThinWidth > 0, 'gridThinWidth cannot be zero'),
        assert(gridThickWidth > 0, 'gridThickWidth cannot be zero'),
        assert(minimumImageSize > 0, 'minimumImageSize cannot be zero');

  @override
  State<ImageCropper> createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  /// [CropController] for managing the crop area and notifying listeners of changes.
  late CropController controller;

  /// Size of the image being displayed, which is updated dynamically with [onSize] function.
  Size size = Size.zero;

  /// The current crop handle point being interacted with, if any.
  CropHandlePoint? cropHandlePoint;

  /// Returns the positions of the crop handles in the current crop area.
  /// It is accessed by [hitTest] to determine which handle is being interacted with.
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
  void dispose() {
    super.dispose();
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
                      gridColor: widget.gridColor,
                      gridInnerColor: widget.gridInnerColor,
                      gridCornerColor: widget.gridCornerColor,
                      cornerSize:
                          widget.showCorners ? widget.gridCornerSize : 0,
                      thinWidth: widget.gridThinWidth,
                      thickWidth: widget.gridThickWidth,
                      scrimColor: widget.scrimColor,
                      showCorners: widget.showCorners,
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

  /// Handles the start of a pan gesture.
  ///
  /// Determines which part of the crop rectangle is being interacted with based on the user's touch point.
  /// and sets the [cropHandlePoint] to the type of handle being interacted with.
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

  /// Handles the update of a pan gesture.
  ///
  /// If a [cropHandlePoint] is set, moves the crop rectangle based on the user's touch point.
  /// If the type of handle is [CropHandle.move], moves the entire crop rectangle.
  /// Otherwise, moves the corner of the crop rectangle based on the [cropHandlePoint].
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

  /// Handles the end of a pan gesture.
  ///
  /// Resets the [cropHandlePoint] to null.
  void onPanEnd(DragEndDetails details) {
    setState(() {
      cropHandlePoint = null;
    });
  }

  /// Determines which part of the crop rectangle is being interacted with based on the user's touch point.
  ///
  /// Returns a [CropHandle] value indicating the corner or action being interacted with.
  ///
  /// - If the touch point is within the touch area of a corner, returns the corresponding corner type.
  /// - Otherwise, returns [CropHandle.move] if the touch point is within the crop rectangle, or [CropHandle.none] if it is outside.
  CropHandle hitTest(Offset point) {
    for (final gridCorner in cropHandlePositions.entries) {
      final area = Rect.fromCenter(
          center: gridCorner.value,
          width: widget.touchSize,
          height: widget.touchSize);
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

  /// Moves the corner of the crop rectangle based on the [cropHandlePoint].
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
}

/// Crop Grid with invisible border, for better touch detection.
class CropGrid extends StatelessWidget {
  final Rect crop;
  final Color gridColor;
  final Color gridInnerColor;
  final Color gridCornerColor;
  final double cornerSize;
  final bool showCorners;
  final double thinWidth;
  final double thickWidth;
  final Color scrimColor;
  final bool isMoving;
  final ValueChanged<Size> onSize;
  final bool alwaysShowThirdLines;

  const CropGrid({
    super.key,
    required this.crop,
    required this.gridColor,
    required this.gridInnerColor,
    required this.gridCornerColor,
    required this.cornerSize,
    required this.thinWidth,
    required this.thickWidth,
    required this.scrimColor,
    required this.showCorners,
    required this.isMoving,
    required this.onSize,
    this.alwaysShowThirdLines = false,
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

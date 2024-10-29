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
///
/// Displays the image with a crop rectangle that can be moved and resized.
class ImageCropper extends StatefulWidget {
  const ImageCropper({
    super.key,
    required this.controller,
    this.scrimColor = Colors.black54,
    this.minimumImageSize = 100,
  }) : assert(
          minimumImageSize > 0,
          'minimumImageSize should be greater than zero.',
        );

  /// Controller for managing crop area and notifying listeners of changes.
  final CropController controller;

  /// [CropGrid] scrim (outside area overlay) color.
  final Color scrimColor;

  /// Minimum pixel size crop [Rect] can be shrunk to.
  final double minimumImageSize;

  @override
  State<ImageCropper> createState() => _ImageCropperState();
}

/// State of an [ImageCropper] managing the state and behavior of the image
/// cropping.
class _ImageCropperState extends State<ImageCropper> {
  /// [Size] of displayed image.
  Size _size = Size.zero;

  /// Current crop handle point being interacted with, if any.
  CropHandlePoint? _handle;

  /// Returns the [CropController] managing the crop area.
  CropController get c => widget.controller;

  /// [Map] of crop handle positions.
  ///
  /// Used to determine which part of crop rectangle is being interacted with.
  Map<CropHandle, Offset> get _positions => <CropHandle, Offset>{
        CropHandle.upperLeft:
            c.crop.value.topLeft.scale(_size.width, _size.height),
        CropHandle.upperRight:
            c.crop.value.topRight.scale(_size.width, _size.height),
        CropHandle.lowerRight:
            c.crop.value.bottomRight.scale(_size.width, _size.height),
        CropHandle.lowerLeft:
            c.crop.value.bottomLeft.scale(_size.width, _size.height),
      };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Obx(() {
          if (c.bitmap.value == null) {
            return const CircularProgressIndicator.adaptive();
          }

          final double maxWidth = constraints.maxWidth;
          final double maxHeight = constraints.maxHeight;
          final double width = _getWidth(maxWidth, maxHeight);
          final double height = _getHeight(maxWidth, maxHeight);

          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(
                width: width,
                height: height,
                child: CustomPaint(
                  painter: RotatedImagePainter(
                    c.bitmap.value!,
                    c.rotation.value,
                  ),
                ),
              ),
              SizedBox(
                width: width,
                height: height,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CropGrid(
                    crop: c.crop.value,
                    scrimColor: widget.scrimColor,
                    isMoving: _handle != null,
                    onSize: (size) => _size = size,
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  /// Returns [CropHandle] that is being interacted with based on [point].
  CropHandle hitTest(Offset point) {
    for (final gridCorner in _positions.entries) {
      final Rect area = Rect.fromCenter(
        center: gridCorner.value,
        width: 50,
        height: 50,
      );

      if (area.contains(point)) {
        return gridCorner.key;
      }
    }

    final Rect area = Rect.fromPoints(
      _positions[CropHandle.upperLeft]!,
      _positions[CropHandle.lowerRight]!,
    );

    return area.contains(point) ? CropHandle.move : CropHandle.none;
  }

  /// Moves the crop rectangle based on the [cropHandlePoint].
  void moveArea(Offset point) {
    final Rect crop = c.crop.value.multiply(_size);

    c.crop.value = Rect.fromLTWH(
      point.dx.clamp(0, _size.width - crop.width),
      point.dy.clamp(0, _size.height - crop.height),
      crop.width,
      crop.height,
    ).divide(_size);
  }

  /// Resizes the crop rectangle by moving corner based on [type] and [point].
  void moveCorner(CropHandle type, Offset point) {
    final Rect crop = c.crop.value.multiply(_size);

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
        maxX = _size.width;
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
        maxX = _size.width;
        if (minX <= maxX) {
          right = point.dx.clamp(minX, maxX);
        }

        minY = top + widget.minimumImageSize;
        maxY = _size.height;
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
        maxY = _size.height;
        if (minY <= maxY) {
          bottom = point.dy.clamp(minY, maxY);
        }
        break;

      default:
        // No-op, as shouldn't be invoked.
        break;
    }

    if (c.aspectRatio != null) {
      final width = right - left;
      final height = bottom - top;

      if (width / height > c.aspectRatio!) {
        switch (type) {
          case CropHandle.upperLeft:
          case CropHandle.lowerLeft:
            left = right - height * c.aspectRatio!;
            break;

          case CropHandle.upperRight:
          case CropHandle.lowerRight:
            right = left + height * c.aspectRatio!;
            break;

          default:
            // No-op, as shouldn't be invoked.
            break;
        }
      } else {
        switch (type) {
          case CropHandle.upperLeft:
          case CropHandle.upperRight:
            top = bottom - width / c.aspectRatio!;
            break;

          case CropHandle.lowerRight:
          case CropHandle.lowerLeft:
            bottom = top + width / c.aspectRatio!;
            break;

          default:
            // No-op, as shouldn't be invoked.
            break;
        }
      }
    }

    c.crop.value = Rect.fromLTRB(left, top, right, bottom).divide(_size);
  }

  /// Updates the [_handle] based on the provided [details].
  void _onPanStart(DragStartDetails details) {
    if (_handle == null) {
      final CropHandle type = hitTest(details.localPosition);

      if (type != CropHandle.none) {
        final Offset basePoint =
            _positions[type == CropHandle.move ? CropHandle.upperLeft : type]!;

        setState(() {
          _handle = CropHandlePoint(type, details.localPosition - basePoint);
        });
      }
    }
  }

  /// Resizes or moves crop rectangle based on the [details] provided.
  void _onPanUpdate(DragUpdateDetails details) {
    if (_handle != null) {
      final Offset offset = details.localPosition - _handle!.offset;

      switch (_handle?.type) {
        case CropHandle.move:
          moveArea(offset);
          break;

        default:
          moveCorner(_handle!.type, offset);
          break;
      }
    }
  }

  /// Sets the [_handle] to `null`.
  void _onPanEnd(DragEndDetails details) {
    setState(() => _handle = null);
  }

  /// Returns ratio of image's width to height.
  double _getImageRatio() => c.bitmapSize.width / c.bitmapSize.height;

  /// Returns image width based on rotation, maximum width and height
  /// constraints.
  double _getWidth(final double maxWidth, final double maxHeight) {
    double imageRatio = _getImageRatio();
    final screenRatio = maxWidth / maxHeight;

    if (c.rotation.value.isSideways) {
      imageRatio = 1 / imageRatio;
    }

    if (imageRatio > screenRatio) {
      return maxWidth;
    }

    return maxHeight * imageRatio;
  }

  /// Returns image height based on rotation, maximum width and maximum height
  /// constraints.
  double _getHeight(final double maxWidth, final double maxHeight) {
    double imageRatio = _getImageRatio();
    final double screenRatio = maxWidth / maxHeight;

    if (c.rotation.value.isSideways) {
      imageRatio = 1 / imageRatio;
    }

    if (imageRatio < screenRatio) {
      return maxHeight;
    }

    return maxWidth / imageRatio;
  }
}

/// [CropGridPainter] with invisible border.
class CropGrid extends StatelessWidget {
  const CropGrid({
    super.key,
    required this.crop,
    required this.scrimColor,
    required this.isMoving,
    required this.onSize,
  });

  /// Crop [Rect] to be displayed.
  final Rect crop;

  /// [Color] of scrim (outside area overlay).
  final Color scrimColor;

  /// Indicator whether crop area is being moved.
  final bool isMoving;

  /// Callback, called when the [Size] of displayed image is changed.
  final void Function(Size value) onSize;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(foregroundPainter: CropGridPainter(this)),
    );
  }
}

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

import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/page/call/widget/scaler.dart';
import '/util/platform_utils.dart';
import 'enums.dart';
import 'painter.dart';

/// Widget for cropping image.
///
/// Displays the image with a crop rectangle that can be moved and resized.
class ImageCropper extends StatefulWidget {
  const ImageCropper({
    super.key,
    required this.image,
    required this.size,
    this.rotation = CropRotation.up,
    this.onCropped,
  });

  /// [Uint8List] of the image to display in [Image.memory].
  final Uint8List image;

  /// [Size] of the [image].
  final Size size;

  /// [CropRotation] of the image.
  final CropRotation rotation;

  final void Function(Rect)? onCropped;

  @override
  State<ImageCropper> createState() => _ImageCropperState();
}

/// State of an [ImageCropper] managing the state and behavior of the image
/// cropping.
class _ImageCropperState extends State<ImageCropper> {
  /// Minimum pixel size crop [Rect] can be shrunk to.
  static const double _minimum = 250;

  /// Current crop handle point being interacted with, if any.
  CropHandlePoint? _handle;

  /// Current [Rect] to display.
  late Rect _crop = Rect.largest;

  bool get _rotated => widget.rotation.isSideways;

  /// Returns the preferred aspect ratio of the [_crop].
  double get _ratio => 1;

  @override
  void initState() {
    CustomMouseCursors.ensureInitialized();
    _ensureSize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final double aspectRatio = _rotated
        ? widget.size.aspectRatio > 1
            ? 1 / widget.size.aspectRatio
            : widget.size.aspectRatio
        : widget.size.aspectRatio > 1
            ? widget.size.aspectRatio
            : 1 / widget.size.aspectRatio;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(builder: (context, constraints) {
        final double maxWidth =
            _rotated ? constraints.maxHeight : constraints.maxWidth;
        final double maxHeight =
            _rotated ? constraints.maxWidth : constraints.maxHeight;

        final Rect real = Rect.fromLTWH(
          _crop.left * maxWidth,
          _crop.top * maxHeight,
          _crop.width * maxWidth,
          _crop.height * maxHeight,
        );

        final Rect position = Rect.fromLTWH(
          _crop.left * maxWidth,
          _crop.top * maxHeight,
          _crop.width * maxWidth,
          _crop.height * maxHeight,
        ).rotated(widget.rotation);

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Image itself.
            RotatedBox(
              quarterTurns: widget.rotation.index,
              child: Image.memory(widget.image),
            ),

            // Grid painter.
            Positioned.fill(
              child: MouseRegion(
                hitTestBehavior: HitTestBehavior.translucent,
                cursor: SystemMouseCursors.grab,
                child: GestureDetector(
                  onPanUpdate: (d) => _move(
                    Offset(
                      (real.left + (_rotated ? d.delta.dy : d.delta.dx)) /
                          maxWidth,
                      (real.top + (_rotated ? d.delta.dx : d.delta.dy)) /
                          maxHeight,
                    ),
                  ),
                  child: CustomPaint(
                    foregroundPainter: CropGridPainter(
                      crop: _crop.rotated(widget.rotation),
                      scrimColor: style.barrierColor,
                      gridColor: style.colors.onPrimary,
                      grid: _handle != null,
                    ),
                  ),
                ),
              ),
            ),

            // Top left.
            Positioned(
              top: position.top - Scaler.size / 2,
              left: position.left - Scaler.size / 2,
              child: _scaler(
                cursor: CustomMouseCursors.resizeUpLeftDownRight,
                width: Scaler.size * 2,
                height: Scaler.size * 2,
                onDrag: (dx, dy) => _resize(
                  CropHandle.topLeft,
                  Offset(
                    (real.left + dx) / maxWidth,
                    (real.top + dy) / maxHeight,
                  ),
                ),
              ),
            ),

            // Top right.
            Positioned(
              top: position.top - Scaler.size / 2,
              left: position.left + position.width - 3 * Scaler.size / 2,
              child: _scaler(
                cursor: CustomMouseCursors.resizeUpRightDownLeft,
                width: Scaler.size * 2,
                height: Scaler.size * 2,
                onDrag: (dx, dy) {
                  _resize(
                    CropHandle.topRight,
                    Offset(
                      (real.right + dx) / maxWidth,
                      (real.top + dy) / maxHeight,
                    ),
                  );
                },
              ),
            ),

            // Bottom left.
            Positioned(
              top: position.top + position.height - 3 * Scaler.size / 2,
              left: position.left - Scaler.size / 2,
              child: _scaler(
                cursor: CustomMouseCursors.resizeUpRightDownLeft,
                width: Scaler.size * 2,
                height: Scaler.size * 2,
                onDrag: (dx, dy) => _resize(
                  CropHandle.bottomLeft,
                  Offset(
                    (real.left + dx) / maxWidth,
                    (real.bottom + dy) / maxHeight,
                  ),
                ),
              ),
            ),

            // Bottom right.
            Positioned(
              top: position.top + position.height - 3 * Scaler.size / 2,
              left: position.left + position.width - 3 * Scaler.size / 2,
              child: _scaler(
                cursor: CustomMouseCursors.resizeUpLeftDownRight,
                width: Scaler.size * 2,
                height: Scaler.size * 2,
                onDrag: (dx, dy) => _resize(
                  CropHandle.bottomRight,
                  Offset(
                    (real.right + dx) / maxWidth,
                    (real.bottom + dy) / maxHeight,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // Returns a [Scaler] scaling the minimized view.
  Widget _scaler({
    Key? key,
    MouseCursor cursor = MouseCursor.defer,
    Function(double, double)? onDrag,
    double? width,
    double? height,
  }) {
    return MouseRegion(
      cursor: cursor,
      child: Scaler(
        key: key,
        onDragUpdate: onDrag,
        width: width ?? Scaler.size,
        height: height ?? Scaler.size,
        opacity: 1,
      ),
    );
  }

  /// Moves the crop rectangle based on the [cropHandlePoint].
  void _move(Offset point) {
    final Rect crop = _crop.multiply(widget.size);

    _crop = Rect.fromLTWH(
      (point.dx * widget.size.width).clamp(0, widget.size.width - crop.width),
      (point.dy * widget.size.height).clamp(
        0,
        widget.size.height - crop.height,
      ),
      crop.width,
      crop.height,
    ).divide(widget.size);

    setState(() {});

    widget.onCropped?.call(_crop);
  }

  void _ensureSize() {
    final Rect crop = _crop.multiply(widget.size);

    double left = crop.left.clamp(0, crop.right - _minimum);
    double top = crop.top.clamp(0, crop.bottom - _minimum);
    double width = crop.width.clamp(_minimum, widget.size.width - _minimum);
    double height = crop.height.clamp(_minimum, widget.size.height - _minimum);

    if (width / height > _ratio) {
      width = height * _ratio;
    } else {
      height = width / _ratio;
    }

    left = widget.size.width / 2 - width / 2;
    top = widget.size.height / 2 - height / 2;

    setState(
      () => _crop = Rect.fromLTWH(left, top, width, height).divide(widget.size),
    );
  }

  /// Resizes the crop rectangle by moving corner based on [type] and [point].
  void _resize(CropHandle type, Offset point) {
    final Rect crop = _crop.multiply(widget.size);

    double left = crop.left;
    double top = crop.top;
    double right = crop.right;
    double bottom = crop.bottom;
    double minX, maxX;
    double minY, maxY;

    switch (type) {
      case CropHandle.topLeft:
        minX = 0;
        maxX = right - _minimum;
        if (minX <= maxX) {
          left = (point.dx * widget.size.width).clamp(minX, maxX);
        }

        minY = 0;
        maxY = bottom - _minimum;
        if (minY <= maxY) {
          top = (point.dy * widget.size.height).clamp(minY, maxY);
        }
        break;

      case CropHandle.topRight:
        minX = left + _minimum;
        maxX = widget.size.width;
        if (minX <= maxX) {
          right = (point.dx * widget.size.width).clamp(minX, maxX);
        }

        minY = 0;
        maxY = bottom - _minimum;
        if (minY <= maxY) {
          top = (point.dy * widget.size.height).clamp(minY, maxY);
        }
        break;

      case CropHandle.bottomRight:
        minX = left + _minimum;
        maxX = widget.size.width;
        if (minX <= maxX) {
          right = (point.dx * widget.size.width).clamp(minX, maxX);
        }

        minY = top + _minimum;
        maxY = widget.size.height;
        if (minY <= maxY) {
          bottom = (point.dy * widget.size.height).clamp(minY, maxY);
        }
        break;

      case CropHandle.bottomLeft:
        minX = 0;
        maxX = right - _minimum;
        if (minX <= maxX) {
          left = (point.dx * widget.size.width).clamp(minX, maxX);
        }

        minY = top + _minimum;
        maxY = widget.size.height;
        if (minY <= maxY) {
          bottom = (point.dy * widget.size.height).clamp(minY, maxY);
        }
        break;

      default:
        // No-op, as shouldn't be invoked.
        break;
    }

    final double width = right - left;
    final double height = bottom - top;

    if (width / height > _ratio) {
      switch (type) {
        case CropHandle.topLeft:
        case CropHandle.bottomLeft:
          left = right - height * _ratio;
          break;

        case CropHandle.topRight:
        case CropHandle.bottomRight:
          right = left + height * _ratio;
          break;

        default:
          // No-op, as shouldn't be invoked.
          break;
      }
    } else {
      switch (type) {
        case CropHandle.topLeft:
        case CropHandle.topRight:
          top = bottom - width / _ratio;
          break;

        case CropHandle.bottomRight:
        case CropHandle.bottomLeft:
          bottom = top + width / _ratio;
          break;

        default:
          // No-op, as shouldn't be invoked.
          break;
      }
    }

    setState(
      () => _crop = Rect.fromLTRB(left, top, right, bottom).divide(widget.size),
    );

    widget.onCropped?.call(_crop);
  }
}

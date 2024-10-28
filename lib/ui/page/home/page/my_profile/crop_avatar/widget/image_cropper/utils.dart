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

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'enums.dart';
import 'widget.dart';

/// Represents handle's position on crop [Rect].
class CropHandlePoint {
  const CropHandlePoint(this.type, this.offset);

  /// Type of crop handle.
  final CropHandle type;

  /// Offset of crop handle
  final Offset offset;
}

/// [CustomPainter] that paints rotated image based on [CropRotation] value.
class RotatedImagePainter extends CustomPainter {
  RotatedImagePainter(this.image, this.rotation);

  /// [ui.Image] to be painted.
  final ui.Image image;

  /// [CropRotation] value to determine rotation.
  final CropRotation rotation;

  /// [Paint] object used for painting image.
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    double targetWidth = size.width;
    double targetHeight = size.height;
    double offset = 0;
    if (rotation != CropRotation.up) {
      if (rotation.isSideways) {
        final double tmp = targetHeight;
        targetHeight = targetWidth;
        targetWidth = tmp;
        offset = (targetWidth - targetHeight) / 2;
        if (rotation == CropRotation.left) {
          offset = -offset;
        }
      }
      canvas.save();
      canvas.translate(targetWidth / 2, targetHeight / 2);
      canvas.rotate(rotation.radians);
      canvas.translate(-targetWidth / 2, -targetHeight / 2);
    }
    _paint.filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(offset, offset, targetWidth, targetHeight),
      _paint,
    );
    if (rotation != CropRotation.up) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// [CustomPainter] to paint [CropGrid].
class CropGridPainter extends CustomPainter {
  CropGridPainter(this.grid);

  /// [CropGrid] configuration.
  final CropGrid grid;

  @override
  void paint(Canvas canvas, Size size) {
    // Constant parameters.
    const Color gridColor = Colors.white70;
    const double cornerSize = 50;

    final Rect full = Offset.zero & size;
    final Rect bounds = grid.crop.multiply(size);
    grid.onSize(size);

    canvas.save();
    canvas.clipRect(bounds, clipOp: ui.ClipOp.difference);
    canvas.drawRect(
      full,
      Paint()
        ..color = grid.scrimColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.restore();

    _drawCorners(canvas, bounds, gridColor, cornerSize);
    _drawBoundaries(canvas, bounds, gridColor, cornerSize);

    if (grid.isMoving) {
      _drawGrid(canvas, bounds, gridColor);
    }
  }

  @override
  bool shouldRepaint(CropGridPainter oldDelegate) =>
      oldDelegate.grid.crop != grid.crop ||
      oldDelegate.grid.isMoving != grid.isMoving;
  @override
  bool hitTest(Offset position) => true;

  /// Draws corners of crop [Rect]
  void _drawCorners(
    Canvas canvas,
    Rect bounds,
    Color gridColor,
    double cornerSize,
  ) {
    final Path path = Path()
      ..addPolygon(
        [
          bounds.topLeft.translate(0, cornerSize),
          bounds.topLeft,
          bounds.topLeft.translate(cornerSize, 0)
        ],
        false,
      )
      ..addPolygon(
        [
          bounds.topRight.translate(0, cornerSize),
          bounds.topRight,
          bounds.topRight.translate(-cornerSize, 0)
        ],
        false,
      )
      ..addPolygon(
        [
          bounds.bottomLeft.translate(0, -cornerSize),
          bounds.bottomLeft,
          bounds.bottomLeft.translate(cornerSize, 0)
        ],
        false,
      )
      ..addPolygon(
        [
          bounds.bottomRight.translate(0, -cornerSize),
          bounds.bottomRight,
          bounds.bottomRight.translate(-cornerSize, 0)
        ],
        false,
      );

    final Paint paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  /// Draws boundaries of crop [Rect]
  void _drawBoundaries(
    Canvas canvas,
    Rect bounds,
    Color gridColor,
    double cornerSize,
  ) {
    final Path path = Path()
      ..addPolygon(
        [
          bounds.topLeft.translate(cornerSize, 0),
          bounds.topRight.translate(-cornerSize, 0)
        ],
        false,
      )
      ..addPolygon(
        [
          bounds.bottomLeft.translate(cornerSize, 0),
          bounds.bottomRight.translate(-cornerSize, 0)
        ],
        false,
      )
      ..addPolygon(
        [
          bounds.topLeft.translate(0, cornerSize),
          bounds.bottomLeft.translate(0, -cornerSize)
        ],
        false,
      )
      ..addPolygon(
        [
          bounds.topRight.translate(0, cornerSize),
          bounds.bottomRight.translate(0, -cornerSize)
        ],
        false,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = gridColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true,
    );
  }

  /// Draws grid lines on crop [Rect]
  void _drawGrid(Canvas canvas, Rect bounds, Color gridColor) {
    final thirdHeight = bounds.height / 3.0;
    final thirdWidth = bounds.width / 3.0;
    final Path path = Path()
      ..addPolygon(
        [
          bounds.topLeft.translate(0, thirdHeight),
          bounds.topRight.translate(0, thirdHeight)
        ],
        false,
      )
      ..addPolygon(
        [
          bounds.bottomLeft.translate(0, -thirdHeight),
          bounds.bottomRight.translate(0, -thirdHeight)
        ],
        false,
      )
      ..addPolygon(
        [
          bounds.topLeft.translate(thirdWidth, 0),
          bounds.bottomLeft.translate(thirdWidth, 0)
        ],
        false,
      )
      ..addPolygon(
        [
          bounds.topRight.translate(-thirdWidth, 0),
          bounds.bottomRight.translate(-thirdWidth, 0)
        ],
        false,
      );

    final Paint paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }
}

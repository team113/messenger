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
import 'widget.dart';
import 'enums.dart';

/// [CropHandlePoint] is a point with a [CropHandle] type and an [Offset] position.
/// It is used to represent the position of a handle on the crop [Rect].
/// The [CropHandle] type is used to determine the type of interaction that should be performed when the handle is dragged.
class CropHandlePoint {
  final CropHandle type;
  final Offset offset;

  CropHandlePoint(this.type, this.offset);
}

/// [RotatedImagePainter] is a [CustomPainter] that paints a rotated image based on the [CropRotation] value.
class RotatedImagePainter extends CustomPainter {
  RotatedImagePainter(this.image, this.rotation);

  /// [ui.Image] to be painted.
  final ui.Image image;

  /// [CropRotation] value to rotate the image.
  final CropRotation rotation;

  /// [Paint] object used to paint the image.
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

/// [CropGridPainter] is a [CustomPainter] that paints the crop grid based on the [CropGrid] configuration.
class CropGridPainter extends CustomPainter {
  CropGridPainter(this.grid);

  /// The [CropGrid] configuration.
  final CropGrid grid;

  @override
  void paint(Canvas canvas, Size size) {
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
          ..isAntiAlias = true);
    canvas.restore();

    if (grid.showCorners) {
      final Path path = Path()
        ..addPolygon([
          bounds.topLeft.translate(0, grid.cornerSize),
          bounds.topLeft,
          bounds.topLeft.translate(grid.cornerSize, 0)
        ], false)
        ..addPolygon([
          bounds.topRight.translate(0, grid.cornerSize),
          bounds.topRight,
          bounds.topRight.translate(-grid.cornerSize, 0)
        ], false)
        ..addPolygon([
          bounds.bottomLeft.translate(0, -grid.cornerSize),
          bounds.bottomLeft,
          bounds.bottomLeft.translate(grid.cornerSize, 0)
        ], false)
        ..addPolygon([
          bounds.bottomRight.translate(0, -grid.cornerSize),
          bounds.bottomRight,
          bounds.bottomRight.translate(-grid.cornerSize, 0)
        ], false);
      final Paint paint = Paint()
        ..color = grid.gridCornerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = grid.thickWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.miter
        ..isAntiAlias = true;
      canvas.drawPath(path, paint);
    }

    final Path path = Path()
      ..addPolygon([
        bounds.topLeft.translate(grid.cornerSize, 0),
        bounds.topRight.translate(-grid.cornerSize, 0)
      ], false)
      ..addPolygon([
        bounds.bottomLeft.translate(grid.cornerSize, 0),
        bounds.bottomRight.translate(-grid.cornerSize, 0)
      ], false)
      ..addPolygon([
        bounds.topLeft.translate(0, grid.cornerSize),
        bounds.bottomLeft.translate(0, -grid.cornerSize)
      ], false)
      ..addPolygon([
        bounds.topRight.translate(0, grid.cornerSize),
        bounds.bottomRight.translate(0, -grid.cornerSize)
      ], false);
    final Paint paint = Paint()
      ..color = grid.gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = grid.thinWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);

    if (grid.isMoving || grid.alwaysShowThirdLines) {
      final thirdHeight = bounds.height / 3.0;
      final thirdWidth = bounds.width / 3.0;
      final Path path = Path()
        ..addPolygon([
          bounds.topLeft.translate(0, thirdHeight),
          bounds.topRight.translate(0, thirdHeight)
        ], false)
        ..addPolygon([
          bounds.bottomLeft.translate(0, -thirdHeight),
          bounds.bottomRight.translate(0, -thirdHeight)
        ], false)
        ..addPolygon([
          bounds.topLeft.translate(thirdWidth, 0),
          bounds.bottomLeft.translate(thirdWidth, 0)
        ], false)
        ..addPolygon([
          bounds.topRight.translate(-thirdWidth, 0),
          bounds.bottomRight.translate(-thirdWidth, 0)
        ], false);
      final Paint paint = Paint()
        ..color = grid.gridInnerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = grid.thinWidth
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CropGridPainter oldDelegate) =>
      oldDelegate.grid.crop != grid.crop || //
      oldDelegate.grid.isMoving != grid.isMoving ||
      oldDelegate.grid.cornerSize != grid.cornerSize ||
      oldDelegate.grid.gridColor != grid.gridColor ||
      oldDelegate.grid.gridCornerColor != grid.gridCornerColor ||
      oldDelegate.grid.gridInnerColor != grid.gridInnerColor;

  @override
  bool hitTest(Offset position) => true;
}

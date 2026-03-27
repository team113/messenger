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

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '/api/backend/schema.dart' show Angle;

/// Enum representing different handles for cropping.
enum CropHandle {
  /// Represents upper-left corner of crop [Rect].
  topLeft,

  /// Represents upper-right corner of crop [Rect].
  topRight,

  /// Represents lower-right corner of crop [Rect].
  bottomRight,

  /// Represents lower-left corner of crop [Rect].
  bottomLeft,
}

/// Possible 90 degree rotations.
enum CropRotation { up, right, down, left }

/// Extension methods for [CropRotation].
extension CropRotationExtension on CropRotation {
  /// Returns rotation in radians clockwise.
  double get radians {
    return switch (this) {
      CropRotation.up => 0,
      CropRotation.right => math.pi / 2,
      CropRotation.down => math.pi,
      CropRotation.left => 3 * math.pi / 2,
    };
  }

  /// Returns rotation in degrees clockwise.
  int get degrees {
    return switch (this) {
      CropRotation.up => 0,
      CropRotation.right => 90,
      CropRotation.down => 180,
      CropRotation.left => 270,
    };
  }

  /// Constructs a [CropRotation] from degrees.
  static CropRotation? fromDegrees(final int degrees) {
    return CropRotation.values.firstWhereOrNull((e) => e.degrees == degrees);
  }

  /// Returns 90 degrees right rotation.
  CropRotation get rotateRight {
    return switch (this) {
      CropRotation.up => CropRotation.right,
      CropRotation.right => CropRotation.down,
      CropRotation.down => CropRotation.left,
      CropRotation.left => CropRotation.up,
    };
  }

  /// Returns 90 degrees left rotation.
  CropRotation get rotateLeft {
    return switch (this) {
      CropRotation.up => CropRotation.left,
      CropRotation.left => CropRotation.down,
      CropRotation.down => CropRotation.right,
      CropRotation.right => CropRotation.up,
    };
  }

  /// Returns `true` if rotation is `right` or `left`.
  bool get isSideways {
    return switch (this) {
      CropRotation.up || CropRotation.down => false,
      CropRotation.right || CropRotation.left => true,
    };
  }

  /// Returns the [Offset] rotated from this [CropRotation].
  Offset getRotatedOffset(
    final Offset offset,
    final double width,
    final double height,
  ) {
    return switch (this) {
      CropRotation.up => Offset(width * offset.dx, height * offset.dy),
      CropRotation.down => Offset(
        width * (1 - offset.dx),
        height * (1 - offset.dy),
      ),
      CropRotation.right => Offset(width * offset.dy, height * (1 - offset.dx)),
      CropRotation.left => Offset(width * (1 - offset.dy), height * offset.dx),
    };
  }

  /// Returns the [Angle] from this [CropRotation].
  Angle get angle {
    return switch (this) {
      CropRotation.up => Angle.deg0,
      CropRotation.right => Angle.deg90,
      CropRotation.down => Angle.deg180,
      CropRotation.left => Angle.deg270,
    };
  }
}

/// Extension methods for [Rect].
extension RectExtensions on Rect {
  /// Returns [Rect] with coordinates multiplied by [size].
  Rect multiply(Size size) {
    return Rect.fromLTRB(
      left * size.width,
      top * size.height,
      right * size.width,
      bottom * size.height,
    );
  }

  /// Returns [Rect] with coordinates divided by [size].
  Rect divide(Size size) {
    return Rect.fromLTRB(
      left / size.width,
      top / size.height,
      right / size.width,
      bottom / size.height,
    );
  }

  /// Returns this [Rect] rotated with [rotation] relative to the [size].
  Rect rotated(CropRotation rotation, Size size) {
    return switch (rotation) {
      CropRotation.up => this,
      CropRotation.right => Rect.fromLTWH(
        size.height - top - height,
        left,
        height,
        width,
      ),
      CropRotation.down => Rect.fromLTWH(
        size.width - width - left,
        size.height - height - top,
        width,
        height,
      ),
      CropRotation.left => Rect.fromLTWH(
        top,
        size.width - width - left,
        width,
        height,
      ),
    };
  }
}

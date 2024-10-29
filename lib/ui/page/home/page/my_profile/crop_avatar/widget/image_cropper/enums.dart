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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/api/backend/schema.dart' show Angle;

/// Enum for representing different handles for cropping.
enum CropHandle {
  /// Represents upper-left corner of crop [Rect].
  upperLeft,

  /// Represents upper-right corner of crop [Rect].
  upperRight,

  /// Represents lower-right corner of crop [Rect].
  lowerRight,

  /// Represents lower-left corner of crop [Rect].
  lowerLeft,

  /// Represents no interaction.
  none,

  /// Represents action of moving entire crop [Rect].
  move
}

/// Enum for all possible 90 degree rotations.
enum CropRotation { up, right, down, left }

/// Extension methods for [CropRotation].
extension CropRotationExtension on CropRotation {
  /// Returns rotation in radians clockwise.
  double get radians {
    switch (this) {
      case CropRotation.up:
        return 0;
      case CropRotation.right:
        return math.pi / 2;
      case CropRotation.down:
        return math.pi;
      case CropRotation.left:
        return 3 * math.pi / 2;
    }
  }

  /// Returns rotation in degrees clockwise.
  int get degrees {
    switch (this) {
      case CropRotation.up:
        return 0;
      case CropRotation.right:
        return 90;
      case CropRotation.down:
        return 180;
      case CropRotation.left:
        return 270;
    }
  }

  /// Returns [CropRotation] from degrees.
  static CropRotation? fromDegrees(final int degrees) {
    for (final CropRotation rotation in CropRotation.values) {
      if (rotation.degrees == degrees) {
        return rotation;
      }
    }
    return null;
  }

  /// Returns 90 degrees right rotation.
  CropRotation get rotateRight {
    switch (this) {
      case CropRotation.up:
        return CropRotation.right;

      case CropRotation.right:
        return CropRotation.down;

      case CropRotation.down:
        return CropRotation.left;

      case CropRotation.left:
        return CropRotation.up;
    }
  }

  /// Returns 90 degrees left rotation.
  CropRotation get rotateLeft {
    switch (this) {
      case CropRotation.up:
        return CropRotation.left;

      case CropRotation.left:
        return CropRotation.down;

      case CropRotation.down:
        return CropRotation.right;

      case CropRotation.right:
        return CropRotation.up;
    }
  }

  /// Returns `true` if rotation is `right` or `left`.
  bool get isSideways {
    switch (this) {
      case CropRotation.up:
      case CropRotation.down:
        return false;

      case CropRotation.right:
      case CropRotation.left:
        return true;
    }
  }

  /// Returns the [Offset] rotated from this [CropRotation].
  Offset getRotatedOffset(
    final Offset offset,
    final double straightWidth,
    final double straightHeight,
  ) {
    switch (this) {
      case CropRotation.up:
        return Offset(
          straightWidth * offset.dx,
          straightHeight * offset.dy,
        );

      case CropRotation.down:
        return Offset(
          straightWidth * (1 - offset.dx),
          straightHeight * (1 - offset.dy),
        );

      case CropRotation.right:
        return Offset(
          straightWidth * offset.dy,
          straightHeight * (1 - offset.dx),
        );

      case CropRotation.left:
        return Offset(
          straightWidth * (1 - offset.dy),
          straightHeight * offset.dx,
        );
    }
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
}

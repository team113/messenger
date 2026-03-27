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

import 'package:json_annotation/json_annotation.dart';

import '/api/backend/schema.dart' show Angle;

part 'crop_area.g.dart';

/// Area for an image cropping.
///
/// Top left corner of the rotated by angle image is considered as `(0, 0)`
/// coordinates start point. So, obviously, [CropArea.bottomRight] point's
/// coordinates should be bigger than the ones of [CropArea.topLeft] point.
@JsonSerializable()
class CropArea {
  CropArea({required this.topLeft, required this.bottomRight, this.angle});

  /// Constructs a [CropArea] from the provided [json].
  factory CropArea.fromJson(Map<String, dynamic> json) =>
      _$CropAreaFromJson(json);

  /// Point of a top left corner of this [CropArea].
  CropPoint topLeft;

  /// Point of a bottom right corner of this [CropArea].
  CropPoint bottomRight;

  /// Angle to rotate image before cropping.
  Angle? angle;

  @override
  bool operator ==(Object other) =>
      other is CropArea &&
      topLeft == other.topLeft &&
      bottomRight == other.bottomRight &&
      angle == other.angle;

  @override
  int get hashCode => Object.hash(topLeft, bottomRight, angle);

  /// Returns a [Map] representing this [CropArea].
  Map<String, dynamic> toJson() => _$CropAreaToJson(this);
}

/// Point in `(X, Y)` coordinates for an image cropping.
@JsonSerializable()
class CropPoint {
  CropPoint({required this.x, required this.y});

  /// Constructs a [CropPoint] from the provided [json].
  factory CropPoint.fromJson(Map<String, dynamic> json) =>
      _$CropPointFromJson(json);

  /// X coordinate of this [CropPoint] in pixels.
  int x;

  /// Y coordinate of this [CropPoint] in pixels.
  int y;

  @override
  bool operator ==(Object other) =>
      other is CropPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  /// Returns a [Map] representing this [CropPoint].
  Map<String, dynamic> toJson() => _$CropPointToJson(this);
}

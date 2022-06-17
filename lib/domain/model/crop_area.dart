// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';
import '/api/backend/schema.dart';

part 'crop_area.g.dart';

/// Area for an image cropping.
///
/// Top left corner of the rotated by angle image is considered as `(0, 0)`
/// coordinates start point. So, obviously, [CropArea.bottomRight] point's
/// coordinates should be bigger than the ones of [CropArea.topLeft] point.
@HiveType(typeId: ModelTypeId.cropArea)
class CropArea {
  /// Point of a top left corner of this [CropArea].
  @HiveField(0)
  CropPoint topLeft;

  /// Point of a bottom right corner of this [CropArea].
  @HiveField(1)
  CropPoint bottomRight;

  /// Angle to rotate image before cropping.
  @HiveField(2)
  Angle? angle;

  CropArea({
    required this.topLeft,
    required this.bottomRight,
    this.angle,
  });
}

/// Point in `(X, Y)` coordinates for an image cropping.
@HiveType(typeId: ModelTypeId.cropPoint)
class CropPoint {
  /// X coordinate of this [CropPoint] in pixels.
  @HiveField(0)
  int x;

  /// Y coordinate of this [CropPoint] in pixels.
  @HiveField(1)
  int y;

  CropPoint({required this.x, required this.y});
}

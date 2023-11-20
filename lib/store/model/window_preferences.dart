// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';

part 'window_preferences.g.dart';

/// [Offset] position and [Size] combined.
@HiveType(typeId: ModelTypeId.windowPreferences)
class WindowPreferences {
  WindowPreferences({this.width, this.height, this.dx, this.dy});

  /// Width component of these [WindowPreferences].
  @HiveField(0)
  double? width;

  /// Height component of these [WindowPreferences].
  @HiveField(1)
  double? height;

  /// Left component of these [WindowPreferences].
  @HiveField(2)
  double? dx;

  /// Top component of these [WindowPreferences].
  @HiveField(3)
  double? dy;

  /// Returns the [Size] of these [WindowPreferences].
  Size? get size =>
      width == null || height == null ? null : Size(width!, height!);

  /// Returns the [Offset] position of these [WindowPreferences].
  Offset? get position => dx == null || dy == null ? null : Offset(dx!, dy!);

  @override
  String toString() => '$position, $size';
}

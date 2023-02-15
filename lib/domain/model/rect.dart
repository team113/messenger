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

/// [Hive] adapter for a [Rect].
class RectAdapter extends TypeAdapter<Rect> {
  @override
  final int typeId = ModelTypeId.rect;

  @override
  Rect read(BinaryReader reader) {
    return Rect.fromLTWH(
      reader.read(),
      reader.read(),
      reader.read(),
      reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Rect obj) {
    writer
      ..write(obj.left)
      ..write(obj.top)
      ..write(obj.width)
      ..write(obj.height);
  }
}

/// Extension adding helper methods to a [Rect].
extension RectExtension on Rect {
  /// Returns a [Map] containing data of these [Rect].
  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'left': left,
        'top': top,
      };

  /// Constructs a [Rect] from the provided [data].
  Rect fromJson(Map<dynamic, dynamic> data) => Rect.fromLTWH(
        data['left'],
        data['top'],
        data['width'],
        data['height'],
      );
}

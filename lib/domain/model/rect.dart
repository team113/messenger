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

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

import 'dart:io';

import 'package:hive/hive.dart';

import '../model_type_id.dart';

part 'cache_info.g.dart';

/// Info about the cache.
@HiveType(typeId: ModelTypeId.cacheInfo)
class CacheInfo extends HiveObject {
  CacheInfo({
    this.files = const [],
    this.size = 0,
    this.modified,
  });

  /// [File]s stored in the cache.
  @HiveField(0)
  List<File> files;

  /// Size of all [files] stored in the cache.
  @HiveField(1)
  int size;

  /// [DateTime] of the last cache modification.
  @HiveField(2)
  DateTime? modified;
}

/// [Hive] adapter for a [File].
class FileAdapter extends TypeAdapter<File> {
  @override
  final int typeId = ModelTypeId.file;

  @override
  File read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return File(
      fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, File obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.path);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

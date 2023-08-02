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

import 'dart:collection';

import 'package:hive/hive.dart';

import '../model_type_id.dart';

/// One gigabyte in bytes.
// ignore: constant_identifier_names
const int GB = 1024 * 1024 * 1024;

/// Info about the cache.
class CacheInfo extends HiveObject {
  CacheInfo({
    HashSet<String>? checksums,
    this.size = 0,
    this.modified,
    this.maxSize = GB,
  }) : checksums = checksums ?? HashSet();

  /// Checksums of the files stored in the cache.
  HashSet<String> checksums;

  /// Size of all files stored in the cache.
  int size;

  /// [DateTime] of the last cache modification.
  DateTime? modified;

  /// Max size of all files stored in the cache.
  int maxSize;
}

/// [Hive] adapter for a [CacheInfo].
class CacheInfoAdapter extends TypeAdapter<CacheInfo> {
  @override
  final int typeId = ModelTypeId.cacheInfo;

  @override
  CacheInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return CacheInfo(
      checksums: HashSet()..addAll(fields[0] as List<String>),
      size: fields[1] as int,
      modified: fields[2] as DateTime?,
      maxSize: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CacheInfo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.checksums.toList())
      ..writeByte(1)
      ..write(obj.size)
      ..writeByte(2)
      ..write(obj.modified)
      ..writeByte(3)
      ..write(obj.maxSize);
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

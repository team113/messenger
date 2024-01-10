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

import 'dart:collection';

import 'package:hive/hive.dart';

import '../model_type_id.dart';

/// One gigabyte in bytes.
// ignore: constant_identifier_names
const int GB = 1024 * 1024 * 1024;

/// Info about some cache.
class CacheInfo extends HiveObject {
  CacheInfo({
    HashSet<String>? checksums,
    this.size = 0,
    this.modified,
    this.maxSize = GB,
  }) : checksums = checksums ?? HashSet();

  /// Checksums of the stored in cache files.
  HashSet<String> checksums;

  /// [DateTime] of the last cache modification.
  DateTime? modified;

  /// Occupied cache size in bytes.
  int size;

  /// Maximum allowed cache size in bytes.
  ///
  /// `null` means that the [maxSize] has no limit.
  int? maxSize;
}

/// [Hive] adapter for a [CacheInfo].
class CacheInfoAdapter extends TypeAdapter<CacheInfo> {
  @override
  final int typeId = ModelTypeId.cacheInfo;

  @override
  CacheInfo read(BinaryReader reader) {
    return CacheInfo(
      checksums: HashSet()..addAll(reader.read() as List<String>),
      size: reader.read() as int,
      modified: reader.read() as DateTime?,
      maxSize: reader.read() as int?,
    );
  }

  @override
  void write(BinaryWriter writer, CacheInfo obj) {
    writer
      ..write(obj.checksums.toList())
      ..write(obj.size)
      ..write(obj.modified)
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

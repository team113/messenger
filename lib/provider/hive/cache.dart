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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/cache_info.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for [CacheInfo].
class CacheInfoHiveProvider extends HiveBaseProvider<CacheInfo> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'cacheInfo';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');
    Hive.maybeRegisterAdapter(CacheInfoAdapter());
  }

  /// Returns the stored [CacheInfo] from [Hive].
  CacheInfo get info {
    Log.debug('get info', '$runtimeType');
    return getSafe(0) ?? CacheInfo();
  }

  /// Updates the stored [CacheInfo] with the provided data.
  Future<void> set({
    HashSet<String>? checksums,
    int? size,
    int? maxSize,
    DateTime? modified,
  }) {
    Log.trace('set($checksums, $size, $maxSize, $modified)', '$runtimeType');

    final CacheInfo info = this.info;

    info.checksums = checksums ?? info.checksums;
    info.size = size ?? info.size;
    info.maxSize = maxSize ?? info.maxSize;
    info.modified = modified ?? info.modified;

    return putSafe(0, info);
  }
}

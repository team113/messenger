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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/cache_info.dart';
import 'base.dart';

/// [Hive] storage for [CacheInfo].
class CacheInfoHiveProvider extends HiveBaseProvider<CacheInfo> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'cacheInfo';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(CacheInfoAdapter());
  }

  /// Returns the stored [CacheInfo] from [Hive].
  CacheInfo? get cacheInfo => getSafe(0);

  /// Stores a new [CacheInfo.filesCount] and [CacheInfo.size] values to
  /// [Hive].
  Future<void> setCountAndSize(int filesCount, int size) {
    CacheInfo info = (box.get(0) ?? CacheInfo());
    info.filesCount = filesCount;
    info.size = size;

    return putSafe(0, info);
  }
}

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

import 'dart:async';
import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:messenger/domain/model/cache_info.dart';
import 'package:messenger/provider/hive/cache.dart';

/// Mocked [CacheInfoHiveProvider] to use in the tests.
class CacheInfoHiveProviderMock extends CacheInfoHiveProvider {
  /// Stored [CacheInfo].
  final CacheInfo _cacheInfo = CacheInfo(maxSize: 1024 * 1024);

  final StreamController<BoxEvent> _boxEvents =
      StreamController<BoxEvent>.broadcast();

  @override
  Stream<BoxEvent> get boxEvents => _boxEvents.stream;

  @override
  String get boxName => 'cacheInfo';

  @override
  void registerAdapters() {}

  /// Returns the stored [CacheInfo] from [Hive].
  @override
  CacheInfo get cacheInfo => _cacheInfo;

  /// Stores a new [CacheInfo] value to [Hive].
  @override
  Future<void> update({
    HashSet<String>? checksums,
    int? size,
    DateTime? modified,
  }) async {
    CacheInfo cacheInfo = this.cacheInfo;
    cacheInfo.checksums = checksums ?? cacheInfo.checksums;
    cacheInfo.size = size ?? cacheInfo.size;
    cacheInfo.modified = modified ?? cacheInfo.modified;
    _boxEvents.add(BoxEvent(0, _cacheInfo, false));
  }
}

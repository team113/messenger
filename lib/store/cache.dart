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

import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/domain/model/cache_info.dart';
import '/domain/repository/cache.dart';
import '/provider/hive/cache.dart';

/// Application cache info repository.
class CacheRepository extends DisposableInterface
    implements AbstractCacheRepository {
  CacheRepository(this._cacheLocal);

  @override
  final Rx<CacheInfo?> cacheInfo = Rx(null);

  /// [CacheInfo] local [Hive] storage.
  final CacheInfoHiveProvider _cacheLocal;

  /// [CacheInfoHiveProvider.boxEvents] subscription.
  StreamIterator? _cacheSubscription;

  @override
  void onInit() {
    cacheInfo.value = _cacheLocal.cacheInfo;
    _initCacheSubscription();
    super.onInit();
  }

  @override
  void onClose() {
    _cacheSubscription?.cancel();
    super.onClose();
  }

  @override
  Future<void> clear() => _cacheLocal.clear();

  /// Initializes [CacheInfoHiveProvider.boxEvents] subscription.
  Future<void> _initCacheSubscription() async {
    _cacheSubscription = StreamIterator(_cacheLocal.boxEvents);
    while (await _cacheSubscription!.moveNext()) {
      BoxEvent event = _cacheSubscription!.current;
      if (event.deleted) {
        cacheInfo.value = null;
      } else {
        cacheInfo.value = event.value;
        cacheInfo.refresh();
      }
    }
  }

  @override
  Future<void> update(int filesCount, int size) =>
      _cacheLocal.setCountAndSize(filesCount, size);
}

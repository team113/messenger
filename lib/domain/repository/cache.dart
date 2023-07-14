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
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../model/cache_info.dart';

/// Application cache repository interface.
abstract class AbstractCacheRepository {
  /// Returns the stored [CacheInfo].
  Rx<CacheInfo?> get cacheInfo;

  /// Gets a file data from cache by the provided [checksum] or downloads by the
  /// provided [url].
  ///
  /// At least one of [url] or [checksum] arguments must be provided.
  ///
  /// Retries itself using exponential backoff algorithm on a failure.
  FutureOr<Uint8List?> get({
    String? url,
    String? checksum,
    Function(int count, int total)? onReceiveProgress,
    CancelToken? cancelToken,
    Future<void> Function()? onForbidden,
  });

  /// Saves the provided [data] to the cache.
  Future<void> save(Uint8List data, [String? checksum]);

  /// Returns indicator whether data with the provided [checksum] exists in the
  /// cache.
  bool exists(String checksum);

  /// Clears the cache.
  Future<void> clear();
}

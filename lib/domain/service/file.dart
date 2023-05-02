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

// Add hive storing all downloaded files? // next pulls?

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '/util/backoff.dart';
import '/util/platform_utils.dart';

/// Service maintaining downloading and caching.
class FileService {
  /// Downloads file by the provided [url] and saves it to cache.
  ///
  /// Retries itself using exponential backoff algorithm on a failure.
  static FutureOr<Uint8List?> get(
    String url,
    String? checksum, {
    Function(int count, int total)? onReceiveProgress,
    CancelToken? cancelToken,
    Future<void> Function()? onForbidden,
  }) async {
    File? file;
    if (checksum != null) {
      if (FIFOCache.exists(checksum)) {
        return FIFOCache.get(checksum);
      }

      if (!PlatformUtils.isWeb) {
        final Directory cache = await getApplicationSupportDirectory();
        file = File('${cache.path}/$checksum');

        if (await file.exists()) {
          return file.readAsBytes();
        }
      }
    }

    final Uint8List data = await Backoff.run(
      () async {
        Response? data;

        try {
          data = await PlatformUtils.dio.get(
            url,
            options: Options(responseType: ResponseType.bytes),
            cancelToken: cancelToken,
            onReceiveProgress: onReceiveProgress,
          );
        } on DioError catch (e) {
          if (e.response?.statusCode == 403) {
            await onForbidden?.call();
          }
        }

        if (data?.data != null && data!.statusCode == 200) {
          return data.data as Uint8List;
        } else {
          throw Exception('Data is not loaded');
        }
      },
      cancelToken,
    );

    Future.sync(() async {
      if (checksum != null) {
        FIFOCache.set(checksum, data);
      }

      if (file != null) {
        await file.create(recursive: true);
        await file.writeAsBytes(data);
      }
    });

    return data;
  }
}

/// Naive [LinkedHashMap]-based cache of [Uint8List]s.
///
/// FIFO policy is used, meaning if [_cache] exceeds its [_maxSize] or
/// [_maxLength], then the first inserted element is removed.
class FIFOCache {
  /// Maximum allowed length of [_cache].
  static const int _maxLength = 1000;

  /// Maximum allowed size in bytes of [_cache].
  static const int _maxSize = 100 << 20; // 100 MiB

  /// [LinkedHashMap] maintaining [Uint8List]s itself.
  static final LinkedHashMap<String, Uint8List> _cache =
      LinkedHashMap<String, Uint8List>();

  /// Returns the total size [_cache] occupies.
  static int get size =>
      _cache.values.map((e) => e.lengthInBytes).fold<int>(0, (p, e) => p + e);

  /// Puts the provided [bytes] to the cache.
  static void set(String key, Uint8List bytes) {
    if (!_cache.containsKey(key)) {
      while (size >= _maxSize) {
        _cache.remove(_cache.keys.first);
      }

      if (_cache.length >= _maxLength) {
        _cache.remove(_cache.keys.first);
      }

      _cache[key] = bytes;
    }
  }

  /// Returns the [Uint8List] of the provided [key], if any is cached.
  static Uint8List? get(String key) => _cache[key];

  /// Indicates whether an item with the provided [key] exists.
  static bool exists(String key) => _cache.containsKey(key);

  /// Removes all entries from the [_cache].
  static void clear() => _cache.clear();
}

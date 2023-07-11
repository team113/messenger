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
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';

import '/domain/repository/cache.dart';
import '/domain/service/disposable_service.dart';
import '/util/backoff.dart';
import '/util/platform_utils.dart';

/// Global variable to access [CacheUtilsImpl].
///
/// May be reassigned to mock specific functionally.
// ignore: non_constant_identifier_names
CacheUtilsImpl CacheUtils = CacheUtilsImpl();

/// Service maintaining downloading and caching.
class CacheUtilsImpl extends DisposableService {
  /// Maximum allowed size of the [cacheDirectory] in bytes.
  static const int maxSize = 1024 * 1024 * 1024; // 1 Gb

  /// Size of all files in the [cacheDirectory] in bytes.
  final RxInt cacheSize = RxInt(0);

  /// Cache info repository, used to retrieve the stored [CacheInfo].
  AbstractCacheRepository? _cacheRepository;

  /// [File]s stored in the [cacheDirectory].
  final List<File> _files = [];

  /// Path to the cache directory.
  Directory? _cacheDirectory;

  /// [StreamSubscription] getting all files from the [cacheDirectory].
  StreamSubscription? _cacheSubscription;

  /// [Mutex] guarding access to the [_optimizeCache] method.
  final Mutex _mutex = Mutex();

  /// Returns a path to the cache directory.
  Future<Directory> get cacheDirectory async {
    _cacheDirectory ??= await getApplicationSupportDirectory();
    return _cacheDirectory!;
  }

  /// Initializes this [CacheUtilsImpl].
  Future<void> init(AbstractCacheRepository cacheRepository) async {
    _cacheRepository = cacheRepository;
    cacheSize.value = cacheRepository.cacheInfo.value?.size ?? 0;

    try {
      final Directory cache = await cacheDirectory;

      _cacheSubscription = cache.list(recursive: true).listen(
        (FileSystemEntity file) async {
          if (file is File) {
            _files.add(file);
          }
        },
        onDone: () async {
          if (_files.length !=
              (cacheRepository.cacheInfo.value?.filesCount ?? 0)) {
            cacheSize.value = await _calculateCacheSize();
            cacheRepository.update(_files.length, cacheSize.value);
            _optimizeCache();
          } else {
            _optimizeCache();
          }
          _cacheSubscription?.cancel();
          _cacheSubscription = null;
        },
      );
    } on MissingPluginException {
      // No-op.
    }
  }

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
  }) {
    if (checksum != null && FIFOCache.exists(checksum)) {
      return FIFOCache.get(checksum);
    }

    return Future.sync(() async {
      if (checksum != null && !PlatformUtils.isWeb) {
        final Directory cache = await cacheDirectory;
        final File file = File('${cache.path}/$checksum');

        if (await file.exists()) {
          final Uint8List bytes = await file.readAsBytes();
          if (sha256.convert(bytes).toString() == checksum) {
            return bytes;
          }
        }
      }

      if (url != null) {
        final Uint8List data = await Backoff.run(
          () async {
            Response? data;

            try {
              data = await (await PlatformUtils.dio).get(
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

        save(data, checksum);

        return data;
      } else {
        return null;
      }
    });
  }

  /// Saves the provided [data] to the [FIFOCache] and to the [cacheDirectory].
  Future<void> save(Uint8List data, [String? checksum]) async {
    checksum ??= sha256.convert(data).toString();
    FIFOCache.set(checksum, data);

    if (!PlatformUtils.isWeb) {
      final Directory cache = await cacheDirectory;
      final File file = File('${cache.path}/$checksum');
      await file.writeAsBytes(data);

      cacheSize.value += data.length;
      _files.add(file);
      _optimizeCache();

      _cacheRepository?.update(_files.length, cacheSize.value);
    }
  }

  /// Returns indicator whether data with the provided [checksum] exists in the
  /// [FIFOCache] or [cacheDirectory].
  bool exists(String checksum) {
    return FIFOCache.exists(checksum) ||
        _files.any((e) => e.path.endsWith(checksum));
  }

  /// Calculates size of the cache.
  Future<int> _calculateCacheSize() async {
    int size = 0;

    for (var file in _files) {
      size += (await file.stat()).size;
    }

    return size;
  }

  /// Deletes files from the [cacheDirectory] if it occupies more then
  /// [maxSize].
  ///
  /// Deletes files with the latest access date.
  Future<void> _optimizeCache() async {
    await _mutex.protect(() async {
      int overflow = cacheSize.value - maxSize;
      if (overflow > 0) {
        overflow += (maxSize * 0.05).floor();

        final List<FileSystemEntity> files = _files.toList();

        Map<FileSystemEntity, FileStat> filesInfo = {};
        for (FileSystemEntity file in files) {
          final FileStat stat = await file.stat();
          if (stat.type == FileSystemEntityType.notFound) {
            _files.remove(file);
          }

          filesInfo[file] = await file.stat();
        }

        files.sortBy((f) => filesInfo[f]!.accessed);

        int deleted = 0;
        for (var file in files) {
          try {
            final FileStat stat = filesInfo[file]!;
            if (stat.type != FileSystemEntityType.notFound) {
              final int fileSize = stat.size;
              await file.delete();
              deleted += fileSize;
              cacheSize.value -= fileSize;
              _files.remove(file);

              if (deleted >= overflow) {
                break;
              }
            }
          } catch (_) {
            // No-op.
          }
        }

        _cacheRepository?.update(_files.length, cacheSize.value);
      }
    });
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

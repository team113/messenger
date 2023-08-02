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
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '/domain/model/cache_info.dart';
import '/domain/service/disposable_service.dart';
import '/provider/hive/cache.dart';
import '/util/backoff.dart';
import '/util/platform_utils.dart';

/// Worker maintaining caching.
class CacheWorker extends DisposableService {
  CacheWorker(this._cacheLocal) {
    instance = this;
  }

  /// Global [CacheWorker] instance.
  static late CacheWorker instance;

  /// Stored [CacheInfo].
  final Rx<CacheInfo?> cacheInfo = Rx(null);

  /// [CacheInfo] local [Hive] storage.
  final CacheInfoHiveProvider? _cacheLocal;

  /// [StreamSubscription] getting all files from the [cacheDirectory].
  StreamSubscription? _cacheSubscription;

  /// [CacheInfoHiveProvider.boxEvents] subscription.
  StreamIterator? _localSubscription;

  /// Path to the cache directory.
  Directory? _cacheDirectory;

  /// [Mutex] guarding access to the [_optimizeCache] method.
  final Mutex _optimizeMutex = Mutex();

  /// [Mutex] guarding access to the [CacheInfoHiveProvider.set] method.
  final Mutex _setMutex = Mutex();

  /// Returns a path to the cache directory.
  Future<Directory> get cacheDirectory async {
    _cacheDirectory ??= await getApplicationSupportDirectory();
    return _cacheDirectory!;
  }

  @override
  Future<void> onInit() async {
    if (!PlatformUtils.isWeb) {
      cacheInfo.value = _cacheLocal?.cacheInfo;
      _initCacheSubscription();

      try {
        final Directory cache = await cacheDirectory;

        if (cacheInfo.value?.modified != (await cache.stat()).modified) {
          _updateInfo();
        }
      } on MissingPluginException {
        // No-op.
      }
    }
    super.onInit();
  }

  @override
  void onClose() {
    _cacheSubscription?.cancel();
    super.onClose();
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

    return Future(() async {
      if (checksum != null && !PlatformUtils.isWeb) {
        final Directory cache = await cacheDirectory;
        final File file = File('${cache.path}/$checksum');

        if (await file.exists()) {
          final Uint8List bytes = await file.readAsBytes();
          if (sha256.convert(bytes).toString() == checksum) {
            FIFOCache.set(checksum, bytes);
            return bytes;
          }
        }
      }

      if (url != null) {
        final Uint8List? data = await Backoff.run(
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
                return null;
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

        if (data != null) {
          save(data, checksum);
        }

        return data;
      } else {
        return null;
      }
    });
  }

  /// Saves the provided [data] to the cache.
  Future<void> save(Uint8List data, [String? checksum]) async {
    checksum ??= sha256.convert(data).toString();
    FIFOCache.set(checksum, data);

    if (!PlatformUtils.isWeb) {
      try {
        final Directory cache = await cacheDirectory;
        final File file = File('${cache.path}/$checksum');
        if (!(await file.exists())) {
          await file.writeAsBytes(data);

          await _setMutex.protect(() async {
            await _cacheLocal?.set(
              CacheInfo(
                checksums: cacheInfo.value!.checksums..add(checksum!),
                size: cacheInfo.value!.size + data.length,
                modified: (await cache.stat()).modified,
              ),
            );
          });

          _optimizeCache();
        }
      } on MissingPluginException {
        // No-op.
      }
    }
  }

  /// Returns indicator whether data with the provided [checksum] exists in the
  /// cache.
  bool exists(String checksum) {
    return FIFOCache.exists(checksum) ||
        (cacheInfo.value?.checksums.contains(checksum) ?? false);
  }

  /// Clears the cache.
  Future<void> clear() async {
    if (cacheInfo.value == null) {
      return;
    }

    final Directory cache = await cacheDirectory;

    final List<File> files = cacheInfo.value!.checksums
        .map((e) => File('${cache.path}/$e'))
        .toList();

    final List<Future> futures = [];
    for (var file in files) {
      futures.add(
        Future(
          () async {
            try {
              await file.delete();
            } catch (_) {
              // No-op.
            }
          },
        ),
      );
    }
    await Future.wait(futures);

    _updateInfo();
  }

  /// Initializes [CacheInfoHiveProvider.boxEvents] subscription.
  Future<void> _initCacheSubscription() async {
    if (_cacheLocal == null) {
      return;
    }

    _localSubscription = StreamIterator(_cacheLocal!.boxEvents);
    while (await _localSubscription!.moveNext()) {
      final BoxEvent event = _localSubscription!.current;
      if (event.deleted) {
        cacheInfo.value = null;
      } else {
        cacheInfo.value = event.value;
        cacheInfo.refresh();
      }
    }
  }

  /// Deletes files from the [cacheDirectory] if it occupies more then
  /// [CacheInfo.maxSize].
  ///
  /// Deletes files with the latest access date.
  Future<void> _optimizeCache() async {
    await _optimizeMutex.protect(() async {
      if (cacheInfo.value == null) {
        return;
      }

      final int maxSize = cacheInfo.value!.maxSize;

      int overflow = cacheInfo.value!.size - maxSize;
      if (overflow > 0) {
        overflow += (maxSize * 0.05).floor();

        final Directory cache = await cacheDirectory;

        final List<File> files = cacheInfo.value!.checksums
            .map((e) => File('${cache.path}/$e'))
            .toList();
        final List<File> removed = [];

        final Map<File, FileStat> filesInfo = {};
        for (File file in files) {
          final FileStat stat = await file.stat();
          if (stat.type == FileSystemEntityType.notFound) {
            removed.add(file);
          }

          filesInfo[file] = await file.stat();
        }

        files.sortBy((f) => filesInfo[f]!.accessed);

        int deleted = 0;
        for (var file in files) {
          try {
            final FileStat? stat = filesInfo[file];
            if (stat != null && stat.type != FileSystemEntityType.notFound) {
              final int fileSize = stat.size;
              await file.delete();
              deleted += fileSize;
              removed.add(file);

              if (deleted >= overflow) {
                break;
              }
            }
          } catch (_) {
            // No-op.
          }
        }

        _setMutex.protect(() async {
          await _cacheLocal?.set(
            CacheInfo(
              checksums: cacheInfo.value!.checksums
                ..removeWhere(
                  (e) => removed.contains(File('${cache.path}/$e')),
                ),
              size: cacheInfo.value!.size - deleted,
              modified: (await cache.stat()).modified,
            ),
          );
        });
      }
    });
  }

  /// Updates the [CacheInfo.size] and [CacheInfo.checksums] values.
  void _updateInfo() async {
    final Directory cache = await cacheDirectory;

    final HashSet<String> checksums = HashSet();
    int cacheSize = 0;

    _cacheSubscription?.cancel();
    _cacheSubscription = cache.list(recursive: true).listen(
      (FileSystemEntity file) async {
        if (file is File) {
          checksums.add(p.basename(file.path));
          final FileStat stat = await file.stat();
          cacheSize += stat.size;
        }
      },
      onDone: () async {
        await _setMutex.protect(() async {
          await _cacheLocal?.set(
            CacheInfo(
              checksums: checksums,
              size: cacheSize,
              modified: (await cache.stat()).modified,
            ),
          );
        });
        _optimizeCache();

        _cacheSubscription?.cancel();
        _cacheSubscription = null;
      },
    );
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

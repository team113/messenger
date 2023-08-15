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

import '/domain/model/cache_info.dart';
import '/domain/service/disposable_service.dart';
import '/provider/hive/cache.dart';
import '/util/backoff.dart';
import '/util/platform_utils.dart';

/// Worker maintaining [File]s cache.
///
/// Uses distributed caching strategy:
/// 1) In-memory cache, represented in [FIFOCache].
/// 2) [File]-system cache.
class CacheWorker extends DisposableService {
  CacheWorker(this._cacheLocal) {
    instance = this;
  }

  /// [CacheWorker] singleton instance.
  static late CacheWorker instance;

  /// [CacheInfo] describing the cache properties.
  late final Rx<CacheInfo> info;

  /// [CacheInfo] local [Hive] storage.
  final CacheInfoHiveProvider? _cacheLocal;

  /// [StreamSubscription] getting all files from the [directory].
  StreamSubscription? _cacheSubscription;

  /// [CacheInfoHiveProvider.boxEvents] subscription.
  StreamIterator? _localSubscription;

  /// [Mutex] guarding saving and deleting files in the cache [directory].
  final Mutex _mutex = Mutex();

  @override
  Future<void> onInit() async {
    info = Rx(_cacheLocal?.cacheInfo ?? CacheInfo());
    _initCacheSubscription();

    if (!PlatformUtils.isWeb) {
      final Directory? cache = await PlatformUtils.cacheDirectory;
      // Recalculate the [info], if [FileStat.modified] mismatch is detected.
      if (cache != null &&
          info.value.modified != (await cache.stat()).modified) {
        _updateInfo();
      }
    }

    super.onInit();
  }

  @override
  void onClose() {
    _cacheSubscription?.cancel();
    super.onClose();
  }

  /// Returns the bytes of [File] identified by its [checksum].
  ///
  /// At least one of [url] or [checksum] arguments must be provided.
  ///
  /// Retries itself using exponential backoff algorithm on a failure, which can
  /// be canceled with a [cancelToken].
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
        final Directory? cache = await PlatformUtils.cacheDirectory;
        if (cache != null) {
          final File file = File('${cache.path}/$checksum');

          if (await file.exists()) {
            final Uint8List bytes = await file.readAsBytes();
            FIFOCache.set(checksum, bytes);
            return bytes;
          }
        }
      }

      if (url != null) {
        try {
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
            add(data, checksum);
          }

          return data;
        } on OperationCanceledException catch (_) {
          return null;
        }
      }

      return null;
    });
  }

  /// Adds the provided [data] to the cache.
  FutureOr<void> add(Uint8List data, [String? checksum]) {
    checksum ??= sha256.convert(data).toString();
    FIFOCache.set(checksum, data);

    if (!PlatformUtils.isWeb) {
      return _mutex.protect(() async {
        final Directory? cache = await PlatformUtils.cacheDirectory;

        if (cache != null) {
          final File file = File('${cache.path}/$checksum');
          if (!(await file.exists())) {
            await file.writeAsBytes(data);

            await _cacheLocal?.update(
              checksums: info.value.checksums..add(checksum!),
              size: info.value.size + data.length,
              modified: (await cache.stat()).modified,
            );

            _optimizeCache();
          }
        }
      });
    }
  }

  /// Indicates whether [checksum] is in the cache.
  bool exists(String checksum) =>
      FIFOCache.exists(checksum) || info.value.checksums.contains(checksum);

  /// Clears the cache in the cache directory.
  Future<void> clear() {
    return _mutex.protect(() async {
      if (PlatformUtils.isWeb) {
        return;
      }

      final Directory? cache = await PlatformUtils.cacheDirectory;
      if (cache != null) {
        final List<File> files =
            info.value.checksums.map((e) => File('${cache.path}/$e')).toList();

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
    });
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
        info.value = CacheInfo();
      } else {
        info.value = event.value;
        info.refresh();
      }
    }
  }

  /// Deletes files from the cache directory, if it occupies more than
  /// [CacheInfo.maxSize].
  ///
  /// Uses LRU (Least Recently Used) approach sorting [File]s by their
  /// [FileStat.accessed] times.
  Future<void> _optimizeCache() {
    return _mutex.protect(() async {
      if (PlatformUtils.isWeb) {
        return;
      }

      final Directory? cache = await PlatformUtils.cacheDirectory;

      final int maxSize = info.value.maxSize;

      int overflow = info.value.size - maxSize;
      if (overflow > 0 && cache != null) {
        overflow += (maxSize * 0.05).floor();

        final List<File> files =
            info.value.checksums.map((e) => File('${cache.path}/$e')).toList();
        final List<String> removed = [];

        final Map<File, FileStat> filesInfo = {};
        for (File file in files) {
          final FileStat stat = await file.stat();
          if (stat.type == FileSystemEntityType.notFound) {
            removed.add(p.basename(file.path));
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
              removed.add(p.basename(file.path));

              if (deleted >= overflow) {
                break;
              }
            }
          } catch (_) {
            // No-op.
          }
        }

        await _cacheLocal?.update(
          checksums: info.value.checksums
            ..removeWhere((e) => removed.contains(e)),
          size: info.value.size - deleted,
          modified: (await cache.stat()).modified,
        );
      }
    });
  }

  /// Updates the [CacheInfo.size] and [CacheInfo.checksums] values.
  void _updateInfo() async {
    final Directory? cache = await PlatformUtils.cacheDirectory;

    if (cache != null) {
      final HashSet<String> checksums = HashSet();
      int size = 0;

      _cacheSubscription?.cancel();
      _cacheSubscription = cache.list(recursive: true).listen(
        (FileSystemEntity file) async {
          if (file is File) {
            checksums.add(p.basename(file.path));
            final FileStat stat = await file.stat();
            size += stat.size;
          }
        },
        onDone: () async {
          await _cacheLocal?.update(
            checksums: checksums,
            size: size,
            modified: (await cache.stat()).modified,
          );

          _optimizeCache();

          _cacheSubscription?.cancel();
          _cacheSubscription = null;
        },
      );
    }
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

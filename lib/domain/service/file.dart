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

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';

import '/domain/service/disposable_service.dart';
import '/util/backoff.dart';
import '/util/platform_utils.dart';

/// Service maintaining downloading and caching.
class FileService extends DisposableService {
  /// Maximum allowed size of the [cacheDirectory] in bytes.
  static int maxSize = 1024 * 1024 * 1024; // 1 Gb

  /// Size of all files in the [cacheDirectory] in bytes.
  Rx<int> cacheSize = Rx<int>(0);

  /// [StreamSubscription] getting all files from the [cacheDirectory].
  StreamSubscription? cacheSubscription;

  /// [StreamSubscription] to the [cacheDirectory] files changes.
  StreamSubscription? cacheChangesSubscription;

  /// [Mutex] guarding access to the [_optimizeCache] method.
  final Mutex _mutex = Mutex();

  /// [DateTime] of the last [_optimizeCache] executing.
  DateTime? _lastOptimization;

  /// [Map] of the [File]s stored in the [cacheDirectory] and their sizes.
  static final Map<FileSystemEntity, int> _files = {};

  /// [Duration] ot the minimal delay between [_optimizeCache] executing.
  static const Duration _optimizationDelay = Duration(minutes: 30);

  /// Path to the cache directory.
  static Directory? _cacheDirectory;

  /// Returns a path to the cache directory.
  static Future<Directory> get cacheDirectory async {
    return _cacheDirectory ?? await getApplicationSupportDirectory();
  }

  @override
  void onInit() async {
    try {
      final Directory cache = await cacheDirectory;

      cacheSubscription = cache.list(recursive: true).listen(
        (FileSystemEntity file) async {
          final FileStat stat = await file.stat();
          if (stat.type != FileSystemEntityType.directory) {
            cacheSize.value += stat.size;
          }
          _files[file] = stat.size;
        },
        onDone: () {
          _optimizeCache();
          cacheSubscription?.cancel();
          cacheSubscription = null;
        },
      );

      cacheChangesSubscription =
          cache.watch(recursive: true).listen((FileSystemEvent e) async {
        if (e.isDirectory) {
          return;
        }

        switch (e.type) {
          case FileSystemEvent.create:
            // Wait until all bytes have been written to the file to get the
            // actual size.
            await Future.delayed(30.seconds);
            final File file = File(e.path);
            final FileStat stat = await file.stat();

            // If size == -1 it's mean that file not exist.
            if (stat.size != -1) {
              cacheSize.value += stat.size;
              _files[File(e.path)] = stat.size;
            }
            break;
          case FileSystemEvent.delete:
            _files.removeWhere((file, size) {
              if (file.path == e.path) {
                cacheSize.value -= size;
                return true;
              }
              return false;
            });
            break;
          default:
            return;
        }

        _optimizeCache();
      });
    } on MissingPluginException {
      // No-op.
    }
    super.onInit();
  }

  @override
  void onClose() {
    cacheSubscription?.cancel();
    cacheChangesSubscription?.cancel();
    super.onClose();
  }

  /// Gets a file data from cache by the provided [checksum] or downloads by the
  /// provided [url].
  ///
  /// At least one of [url] or [checksum] arguments must be provided.
  ///
  /// Retries itself using exponential backoff algorithm on a failure.
  static FutureOr<Uint8List?> get({
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
      File? file;
      if (checksum != null) {
        if (!PlatformUtils.isWeb) {
          final Directory cache = await cacheDirectory;
          file = File('${cache.path}/$checksum');

          if (await file.exists()) {
            return file.readAsBytes();
          }
        }
      }

      if (url != null) {
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
            await file.writeAsBytes(data);
          }
        });

        return data;
      } else {
        return null;
      }
    });
  }

  /// Saves the provided [data] to the [FIFOCache] and to the [cacheDirectory].
  static Future<void> save(Uint8List data, String checksum) async {
    FIFOCache.set(checksum, data);

    final Directory cache = await cacheDirectory;
    final File file = File('${cache.path}/$checksum');
    await file.writeAsBytes(data);
  }

  /// Returns indicator whether data with the provided [checksum] exists in the
  /// [FIFOCache] or [cacheDirectory].
  static bool exists(String? checksum) {
    if (checksum == null) {
      return false;
    }

    return FIFOCache.exists(checksum) ||
        _files.keys.any((e) => e.path.endsWith(checksum));
  }

  /// Deletes files from the [cacheDirectory] if it occupies more then
  /// [maxSize].
  ///
  /// Deletes files with the latest access date.
  Future<void> _optimizeCache() async {
    await _mutex.protect(() async {
      int overflow = cacheSize.value - maxSize;
      if (overflow > 0 &&
          (_lastOptimization == null ||
              _lastOptimization!
                  .add(_optimizationDelay)
                  .isBefore(DateTime.now()))) {
        final List<FileSystemEntity> files = _files.keys.toList();
        files.sortBy((f) => f.statSync().accessed);

        int deleted = 0;
        for (var file in files) {
          try {
            final int fileSize = _files[file] ?? 0;
            await file.delete(recursive: true);
            deleted += fileSize;
            cacheSize.value -= fileSize;

            if (deleted >= overflow) {
              break;
            }
          } catch (_, __) {
            // No-op.
          }
        }
      }

      _lastOptimization = DateTime.now();
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

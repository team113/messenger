// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_thumbhash/flutter_thumbhash.dart' as t;
import 'package:get/get.dart' hide Response;
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;

import '/domain/model/cache_info.dart';
import '/domain/model/file.dart';
import '/domain/service/disposable_service.dart';
import '/provider/drift/cache.dart';
import '/provider/drift/download.dart';
import '/util/backoff.dart';
import '/util/log.dart';
import '/util/obs/rxmap.dart';
import '/util/platform_utils.dart';

/// Worker maintaining [File]s cache and downloads.
///
/// Uses [File]-system cache.
class CacheWorker extends Dependency {
  CacheWorker(this._cacheLocal, this._downloadLocal) {
    instance = this;
  }

  /// [CacheWorker] singleton instance.
  static late CacheWorker instance;

  /// Observable map of [Downloading]s.
  final RxObsMap<String, Downloading> downloads =
      RxObsMap<String, Downloading>();

  /// [CacheInfo] describing the cache properties.
  final Rx<CacheInfo> info = Rx(CacheInfo());

  /// Checksums of the stored caches.
  final HashSet<String> hashes = HashSet();

  /// [Directory] this [CacheWorker] is to put the [hashes] to.
  final Rx<Directory?> cacheDirectory = Rx(null);

  /// [Directory] this [CacheWorker] is to put the [downloads] to.
  final Rx<Directory?> downloadsDirectory = Rx(null);

  /// [CacheInfo] local storage.
  final CacheDriftProvider? _cacheLocal;

  /// Downloaded [File.path]s local storage.
  final DownloadDriftProvider? _downloadLocal;

  /// Cached thumbhash [ImageProvider]s.
  final Map<ThumbHash, ImageProvider> _thumbhashProviders = {};

  /// [Directory.list] subscription used in [_updateInfo].
  StreamSubscription? _cacheSubscription;

  /// [Mutex] guarding access to [PlatformUtilsImpl.cacheDirectory].
  final Mutex _mutex = Mutex();

  @override
  Future<void> onInit() async {
    _cacheLocal?.checksums().then((v) => hashes.addAll(v));

    info.value = await _cacheLocal?.read() ?? info.value;

    final Directory? cache = cacheDirectory.value ??=
        await PlatformUtils.cacheDirectory;

    // Recalculate the [info], if [FileStat.modified] mismatch is detected.
    if (cache != null && info.value.modified != (await cache.stat()).modified) {
      _updateInfo();
    }

    if (!PlatformUtils.isWeb) {
      PlatformUtils.downloadsDirectory.then(
        (e) => downloadsDirectory.value = e,
      );
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
  FutureOr<CacheEntry> get({
    String? url,
    String? checksum,
    Function(int count, int total)? onReceiveProgress,
    CancelToken? cancelToken,
    Future<void> Function()? onForbidden,
    CacheResponseType responseType = CacheResponseType.bytes,
  }) {
    // Web does not support file caching.
    if (PlatformUtils.isWeb) {
      responseType = CacheResponseType.bytes;
    }

    return Future(() async {
      if (checksum != null) {
        final Directory? cache = cacheDirectory.value ??=
            await PlatformUtils.cacheDirectory;

        if (cache != null) {
          final File file = File('${cache.path}/$checksum');

          if (await file.exists()) {
            switch (responseType) {
              case CacheResponseType.file:
                return CacheEntry(file: file);

              case CacheResponseType.bytes:
                final Uint8List bytes = await file.readAsBytes();

                if (bytes.lengthInBytes != 0) {
                  return CacheEntry(bytes: bytes);
                }
            }
          }
        }
      }

      if (url != null) {
        try {
          final Uint8List? data = await Backoff.run(() async {
            Response? data;

            try {
              data = await (await PlatformUtils.dio).get(
                url,
                options: Options(responseType: ResponseType.bytes),
                cancelToken: cancelToken,
                onReceiveProgress: onReceiveProgress,
              );
            } on DioException catch (e) {
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
          }, cancel: cancelToken);

          switch (responseType) {
            case CacheResponseType.file:
              return Future(
                () async => CacheEntry(
                  file: data == null ? null : await add(data, checksum, url),
                ),
              );

            case CacheResponseType.bytes:
              if (data != null) {
                add(data, checksum, url);
              }
              return CacheEntry(bytes: data);
          }
        } on OperationCanceledException catch (_) {
          return CacheEntry();
        }
      }

      return CacheEntry();
    });
  }

  /// Returns the [ImageProvider] for the provided [thumbhash].
  ImageProvider getThumbhashProvider(ThumbHash thumbhash) {
    final ImageProvider thumbhashProvider =
        _thumbhashProviders[thumbhash] ??
        (_thumbhashProviders[thumbhash] = t.ThumbHash.fromBase64(
          thumbhash.val,
        ).toImage());

    if (_thumbhashProviders.length > 100) {
      _thumbhashProviders.remove(_thumbhashProviders.keys.first);
    }

    return thumbhashProvider;
  }

  /// Adds the provided [data] to the cache.
  FutureOr<File?> add(Uint8List data, [String? checksum, String? url]) {
    // Calculating SHA-256 hash from [data] on Web freezes the application.
    if (!PlatformUtils.isWeb) {
      checksum ??= sha256.convert(data).toString();
    }

    return _mutex.protect(() async {
      final Directory? cache = cacheDirectory.value ??=
          await PlatformUtils.cacheDirectory;

      if (cache != null) {
        final File file = File('${cache.path}/$checksum');
        if (!(await file.exists())) {
          await file.writeAsBytes(data);

          info.value.size = info.value.size + data.length;
          info.value.modified = (await cache.stat()).modified;
          info.refresh();
          hashes.add('$checksum');
          await _cacheLocal?.upsert(info.value);
          await _cacheLocal?.register([checksum!]);

          _optimizeCache();
        }

        return file;
      }

      return null;
    });
  }

  /// Downloads a file from the provided [url].
  Downloading download(
    String url,
    String filename,
    int? size, {
    String? checksum,
    String? to,
  }) {
    Downloading? downloading = downloads[checksum]?..start(url, to: to);

    if (downloading == null) {
      downloading = Downloading(
        checksum,
        filename,
        size,
        onDownloaded: (file) {
          if (checksum != null) {
            _downloadLocal?.upsert(checksum, file.path);
          }
        },
      )..start(url, to: to);

      if (checksum != null) {
        downloads[checksum] = downloading;
      }
    }

    return downloading;
  }

  /// Checks that the [File] with provided parameters is downloaded.
  Future<File?> checkDownloaded({
    required String filename,
    String? checksum,
    int? size,
    String? url,
  }) async {
    final Downloading? downloading = downloads[checksum];
    if (downloading != null) {
      return downloading.file;
    }

    File? file;
    if (checksum != null) {
      final String? path = await _downloadLocal?.read(checksum);

      if (path != null) {
        file = File(path);

        if (!await file.exists() || await file.length() != size) {
          file = null;
          _downloadLocal?.delete(checksum);
        }
      }
    } else {
      file = await PlatformUtils.fileExists(filename, size: size, url: url);
    }

    if (checksum != null && file != null) {
      downloads[checksum] = Downloading.completed(
        checksum,
        filename,
        size,
        file.path,
        onDownloaded: (file) => _downloadLocal?.upsert(checksum, file.path),
      );

      _downloadLocal?.upsert(checksum, file.path);
    }

    return file;
  }

  /// Opens a [File] identified by its [checksum], if downloaded, or otherwise
  /// returns `false`.
  Future<bool> open(String? checksum, int? size) async {
    final Downloading? downloading = downloads[checksum];

    if (downloading?.file != null) {
      final File file = downloading!.file!;

      if (await file.exists() && await file.length() == size) {
        await PlatformUtils.openDirectoryOrFile(file);
        return true;
      } else {
        downloading.markAsNotStarted();
        _downloadLocal?.delete(checksum!);
      }
    }

    return false;
  }

  /// Indicates whether [checksum] is in the cache.
  bool exists(String checksum) => hashes.contains(checksum);

  /// Clears the cache in the cache directory.
  Future<void> clear() {
    return _mutex.protect(() async {
      final Directory? cache = cacheDirectory.value ??=
          await PlatformUtils.cacheDirectory;

      if (cache != null) {
        final List<File> files = hashes
            .map((e) => File('${cache.path}/$e'))
            .toList();

        final List<Future> futures = [];
        for (var file in files) {
          futures.add(
            Future(() async {
              try {
                await file.delete();
              } catch (_) {
                // No-op.
              }
            }),
          );
        }

        await Future.wait(futures);

        _updateInfo();
      }
    });
  }

  /// Sets the maximum allowed size of the cache.
  Future<void> setMaxSize(int? size) async {
    Log.debug('setMaxSize($size)', '$runtimeType');

    info.value.maxSize = size;
    info.refresh();
    await _cacheLocal?.upsert(info.value);
  }

  /// Waits for locking operations to release the lock.
  @visibleForTesting
  Future<void> ensureOptimized() => _mutex.protect(() async {});

  /// Deletes files from the cache directory, if it occupies more than
  /// [CacheInfo.maxSize].
  ///
  /// Uses LRU (Least Recently Used) approach sorting [File]s by their
  /// [FileStat.accessed] times.
  Future<void> _optimizeCache() {
    if (info.value.maxSize == null) {
      return Future.value();
    }

    return _mutex.protect(() async {
      final Directory? cache = cacheDirectory.value ??=
          await PlatformUtils.cacheDirectory;

      int overflow = info.value.size - info.value.maxSize!;
      if (overflow > 0 && cache != null) {
        overflow += (info.value.maxSize! * 0.05).floor();

        final List<File> files = hashes
            .map((e) => File('${cache.path}/$e'))
            .toList();
        final List<String> removed = [];

        final Map<File, FileStat> stats = {};
        for (File file in files) {
          final FileStat stat = await file.stat();
          if (stat.type == FileSystemEntityType.notFound) {
            removed.add(p.basename(file.path));
          }

          stats[file] = await file.stat();
        }

        files.sortBy((f) => stats[f]!.accessed);

        int deleted = 0;
        for (File file in files) {
          try {
            final FileStat? stat = stats[file];

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

        info.value.size = info.value.size - deleted;
        info.value.modified = (await cache.stat()).modified;
        info.refresh();
        hashes.removeAll(removed);
        await _cacheLocal?.upsert(info.value);
        await _cacheLocal?.unregister(removed);
      }
    });
  }

  /// Updates the [CacheInfo.size] and [CacheInfo.checksums] values.
  void _updateInfo() async {
    final Directory? cache = cacheDirectory.value ??=
        await PlatformUtils.cacheDirectory;

    if (cache != null) {
      final HashSet<String> checksums = HashSet();
      int size = 0;

      _cacheSubscription?.cancel();
      _cacheSubscription = cache
          .list(recursive: true)
          .listen(
            (FileSystemEntity file) async {
              if (file is File) {
                checksums.add(p.basename(file.path));
                final FileStat stat = await file.stat();
                size += stat.size;
              }
            },
            onDone: () async {
              await _cacheLocal?.clear();
              info.value.size = size;
              info.value.modified = (await cache.stat()).modified;
              info.refresh();
              hashes.addAll(checksums);
              await _cacheLocal?.upsert(info.value);
              await _cacheLocal?.register(checksums.toList());

              _optimizeCache();

              _cacheSubscription?.cancel();
              _cacheSubscription = null;
            },
          );
    }
  }
}

/// [File] downloading entry.
class Downloading {
  Downloading(this.checksum, this.filename, this.size, {this.onDownloaded});

  /// Creates a completed [Downloading].
  Downloading.completed(
    this.checksum,
    this.filename,
    this.size,
    String path, {
    this.onDownloaded,
  }) {
    file = File(path);
    status.value = DownloadStatus.isFinished;
  }

  /// SHA-256 checksum of the [file] this [Downloading] is bound to.
  final String? checksum;

  /// Filename of the [file] this [Downloading] is bound to.
  final String filename;

  /// Size in bytes of the [file] this [Downloading] is bound to.
  final int? size;

  /// Downloaded file itself.
  File? file;

  /// Progress of this [Downloading].
  final RxDouble progress = RxDouble(0);

  /// [DownloadStatus] of this [Downloading].
  final Rx<DownloadStatus> status = Rx(DownloadStatus.notStarted);

  /// Callback, called when the [file] is downloaded.
  final void Function(File)? onDownloaded;

  /// [Completer] resolving once the [file] is downloaded.
  Completer<File?>? _completer;

  /// CancelToken canceling the [file] downloading.
  CancelToken _token = CancelToken();

  /// Returns [Future] completing when this [Downloading] is finished or
  /// canceled.
  Future<File?>? get future => _completer?.future;

  /// Starts the [file] downloading.
  Future<void> start(String url, {String? to}) async {
    progress.value = 0;
    status.value = DownloadStatus.inProgress;
    _completer = Completer<File?>();

    try {
      file = await PlatformUtils.download(
        url,
        filename,
        size,
        path: to,
        checksum: checksum,
        onReceiveProgress: (count, total) => progress.value = count / total,
        cancelToken: _token,
      );
      _completer?.complete(file);

      if (file != null) {
        status.value = DownloadStatus.isFinished;
        onDownloaded?.call(file!);
      } else {
        status.value = DownloadStatus.notStarted;
      }
    } catch (e) {
      _completer?.completeError(e);
      status.value = DownloadStatus.notStarted;
    }
  }

  /// Cancels the [file] downloading.
  void cancel() {
    status.value = DownloadStatus.notStarted;
    if (_completer?.isCompleted == false) {
      _completer?.complete(null);
    }
    _completer = null;
    _token.cancel();
    _token = CancelToken();
  }

  /// Marks this [Downloading] as not started.
  void markAsNotStarted() {
    if (status.value == DownloadStatus.isFinished) {
      status.value = DownloadStatus.notStarted;
      file = null;
    }
  }
}

/// Status of a [Downloading].
enum DownloadStatus {
  /// Downloading has not yet started or canceled.
  notStarted,

  /// Downloading is in progress.
  inProgress,

  /// Downloaded successfully.
  isFinished,
}

/// Cache entry of [file] and/or its [bytes].
class CacheEntry {
  CacheEntry({this.file, this.bytes});

  /// [File] of this [CacheEntry].
  final File? file;

  /// Byte data of this [CacheEntry].
  final Uint8List? bytes;
}

/// Response type of the [CacheWorker.get] function.
enum CacheResponseType {
  /// Function returns a [File].
  file,

  /// Function returns a [Uint8List].
  bytes,
}

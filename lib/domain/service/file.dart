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
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';

import '/config.dart';
import '/util/backoff.dart';
import '/util/platform_utils.dart';

/// Service maintaining downloading and caching.
class FileService {
  /// [Mutex] protecting cache directory creating.
  static final Mutex _directoryMutex = Mutex();

  /// Downloads file by the provided [url] and saves it to cache.
  ///
  /// Retries itself using exponential backoff algorithm on a failure.
  static Future<Uint8List?> downloadAndCache(
    String url,
    String? checksum, {
    Function(int count, int total)? onReceiveProgress,
    CancelToken? cancelToken,
    Future<void> Function()? onForbidden,
  }) async {
    File? file;
    if (checksum != null && !PlatformUtils.isWeb) {
      final Directory cache = await getApplicationDocumentsDirectory();
      file = File('${cache.path}${Config.downloads}/$checksum');

      if (await file.exists()) {
        return file.readAsBytes();
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
          );
        } on DioError catch (e) {
          if (e.response?.statusCode == 403) {
            print('await onForbidden?.call();');
            await onForbidden?.call();
          }
        }

        if (data?.data != null && data!.statusCode == 200) {
          return data.data as Uint8List;
        } else {
          throw Exception('Image is not loaded');
        }
      },
      cancelToken,
    );

    if (file != null && !PlatformUtils.isWeb) {
      Future.sync(() async {
        try {
          await file!.writeAsBytes(data);
        } catch (_) {
          await _createCacheDirectory();
          await file!.writeAsBytes(data);
        }
      });
    }

    return data;
  }

  /// Creates the cache directory.
  static Future<void> _createCacheDirectory() async {
    final bool locked = _directoryMutex.isLocked;

    await _directoryMutex.protect(() async {
      if(locked) {
        return;
      }

      final Directory cache = await getApplicationDocumentsDirectory();
      final Directory directory = Directory('${cache.path}${Config.downloads}');

      if (!await directory.exists()) {
        await directory.create();
      }
    });
  }
}

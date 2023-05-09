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

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '/util/platform_utils.dart';
import '/util/obs/rxlist.dart';

/// Service maintaining downloading and caching.
class FileService {
  /// Observable list of created [Downloading]s.
  static RxObsList<Downloading> downloads = RxObsList<Downloading>();

  /// Starts downloading of the file by provided [url].
  static Downloading download(
    String url,
    String? checksum,
    String filename,
    int? size, {
    String? path,
    bool downloadIfExist = false,
  }) {
    Downloading? downloading;
    if (checksum != null) {
      downloading = downloads.firstWhereOrNull((e) => e.checksum == checksum)
        ?..start(url, path: path, downloadIfExist: downloadIfExist);
    }

    if (downloading == null) {
      downloading = Downloading(checksum, filename, size)
        ..start(url, path: path, downloadIfExist: downloadIfExist);
      downloads.add(downloading);
    }

    return downloading;
  }
}

/// A downloading process.
class Downloading {
  Downloading(this.checksum, this.filename, this.size);

  /// SHA-256 checksum of the file to download.
  final String? checksum;

  /// Filename of the file to download.
  final String filename;

  /// Size in bytes of the file to download.
  int? size;

  /// Downloaded file.
  File? file;

  /// Progress of this [Downloading].
  RxDouble progress = RxDouble(0);

  /// [DownloadStatus] of this [Downloading].
  Rx<DownloadStatus> status = Rx(DownloadStatus.notStarted);

  /// [Completer] resolving once the [file] is downloaded.
  Completer<File?>? _completer;

  /// CancelToken canceling the [file] downloading.
  CancelToken _token = CancelToken();

  /// [Future] completing when this [Downloading] is finished or canceled.
  Future<File?>? get future => _completer?.future;

  /// Starts the [file] downloading.
  Future<void> start(
    String url, {
    String? path,
    bool downloadIfExist = false,
  }) async {
    progress.value = 0;
    status.value = DownloadStatus.inProgress;
    _completer = Completer<File?>();

    try {
      file = await PlatformUtils.download(
        url,
        filename,
        size,
        path: path,
        downloadIfExist: downloadIfExist,
        onReceiveProgress: (count, total) => progress.value = count / total,
        cancelToken: _token,
      );
      _completer?.complete(file);

      if (file != null) {
        status.value = DownloadStatus.isFinished;
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
    _completer?.complete(null);
    _completer = null;
    _token.cancel();
    _token = CancelToken();
  }
}

/// Download status of a [Downloading].
enum DownloadStatus {
  /// Download has not yet started.
  notStarted,

  /// Download is in progress.
  inProgress,

  /// Downloaded successfully.
  isFinished,
}

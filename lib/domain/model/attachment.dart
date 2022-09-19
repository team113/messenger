// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../model_type_id.dart';
import '/config.dart';
import '/util/new_type.dart';
import '/util/platform_utils.dart';
import 'image_gallery_item.dart';
import 'native_file.dart';
import 'sending_status.dart';

part 'attachment.g.dart';

/// Attachment of a [ChatItem].
abstract class Attachment extends HiveObject {
  Attachment(
    this.id,
    this.original,
    this.filename,
    this.size,
  );

  /// Unique ID of this [Attachment].
  @HiveField(0)
  AttachmentId id;

  /// Path on a files storage to the original file representing this
  /// [Attachment].
  @HiveField(1)
  Original original;

  /// Uploaded file's name.
  @HiveField(2)
  String filename;

  /// Uploaded file's size in bytes.
  @HiveField(3)
  int size;
}

/// Image [Attachment].
@HiveType(typeId: ModelTypeId.imageAttachment)
class ImageAttachment extends Attachment {
  ImageAttachment({
    required AttachmentId id,
    required Original original,
    required String filename,
    required int size,
    required this.big,
    required this.medium,
    required this.small,
  }) : super(id, original, filename, size);

  /// Path on a files storage to a `big` [ImageAttachment]'s view of
  /// `400px`x`400px` size.
  @HiveField(4)
  String big;

  /// Path on a files storage to a `medium` [ImageAttachment]'s view of
  /// `200px`x`200px` size.
  @HiveField(5)
  String medium;

  /// Path on a files storage to a `small` [ImageAttachment]'s view of
  /// `30px`x`30px` size.
  @HiveField(6)
  String small;
}

/// Plain file [Attachment].
@HiveType(typeId: ModelTypeId.fileAttachment)
class FileAttachment extends Attachment {
  FileAttachment({
    required AttachmentId id,
    required Original original,
    required String filename,
    required int size,
  }) : super(id, original, filename, size);

  /// Path to the downloaded [FileAttachment] in the local filesystem.
  @HiveField(4)
  String? path;

  /// [DownloadStatus] of this [FileAttachment].
  Rx<DownloadStatus> downloadStatus = Rx(DownloadStatus.notStarted);

  /// Download progress of this [FileAttachment].
  RxDouble progress = RxDouble(0);

  /// [CancelToken] canceling the download of this [FileAttachment], if any.
  CancelToken? _token;

  /// Indicator whether this [FileAttachment] has already been [init]ialized.
  bool _initialized = false;

  /// Indicates whether this [FileAttachment] is downloading.
  bool get isDownloading => downloadStatus.value == DownloadStatus.inProgress;

  // TODO: Compare hashes.
  /// Initializes the [downloadStatus].
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    if (path != null) {
      File file = File(path!);
      if (await file.exists() && await file.length() == size) {
        downloadStatus.value = DownloadStatus.isFinished;
        return;
      }
    }

    String downloads = await PlatformUtils.downloadsDirectory;
    String name = p.basenameWithoutExtension(filename);
    String ext = p.extension(filename);
    File file = File('$downloads/$filename');

    for (int i = 1; await file.exists() && await file.length() != size; ++i) {
      file = File('$downloads/$name ($i)$ext');
    }

    if (await file.exists()) {
      downloadStatus.value = DownloadStatus.isFinished;
      path = file.path;
    } else {
      downloadStatus.value = DownloadStatus.notStarted;
      path = null;
    }
  }

  /// Downloads this [FileAttachment].
  Future<void> download() async {
    try {
      downloadStatus.value = DownloadStatus.inProgress;
      progress.value = 0;

      _token = CancelToken();

      File? file = await PlatformUtils.download(
        '${Config.url}/files${original.val}',
        filename,
        onReceiveProgress: (count, total) => progress.value = count / total,
        cancelToken: _token,
      );

      if (_token?.isCancelled == true || file == null) {
        downloadStatus.value = DownloadStatus.notStarted;
        path = null;
      } else {
        downloadStatus.value = DownloadStatus.isFinished;
        path = file.path;
      }
    } catch (_) {
      downloadStatus.value = DownloadStatus.notStarted;
      path = null;
    }
  }

  /// Opens this [FileAttachment], if downloaded, or otherwise downloads it.
  Future<void> open() async {
    if (path != null) {
      File file = File(path!);

      if (await file.exists() && await file.length() == size) {
        await OpenFile.open(path!);
        return;
      }
    }

    await download();
  }

  /// Cancels the downloading of this [FileAttachment].
  void cancelDownload() => _token?.cancel();
}

/// Unique ID of an [Attachment].
@HiveType(typeId: ModelTypeId.attachmentId)
class AttachmentId extends NewType<String> {
  const AttachmentId(String val) : super(val);

  /// Constructs a dummy [AttachmentId].
  factory AttachmentId.local() => AttachmentId('local_${const Uuid().v4()}');
}

/// [Attachment] stored in a [NativeFile] locally.
@HiveType(typeId: ModelTypeId.localAttachment)
class LocalAttachment extends Attachment {
  LocalAttachment(this.file, {SendingStatus status = SendingStatus.error})
      : status = Rx(status),
        super(
          AttachmentId.local(),
          const Original(''),
          file.name,
          file.size,
        );

  /// [NativeFile] representing this [LocalAttachment].
  @HiveField(4)
  NativeFile file;

  /// [SendingStatus] of this [LocalAttachment].
  final Rx<SendingStatus> status;

  /// Upload progress of this [LocalAttachment].
  final Rx<double> progress = Rx(0);

  /// [Completer] resolving once this [LocalAttachment]'s uploading is finished.
  final Rx<Completer<Attachment>?> upload = Rx<Completer<Attachment>?>(null);

  /// [Completer] resolving once this [LocalAttachment]'s reading is finished.
  final Rx<Completer<void>?> read = Rx<Completer<void>?>(null);
}

/// Download status of a [FileAttachment].
enum DownloadStatus {
  /// Download has not yet started.
  notStarted,

  /// Download is in progress.
  inProgress,

  /// Downloaded successfully.
  isFinished,
}

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
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';

import '../model_type_id.dart';
import '/domain/service/file.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import 'file.dart';
import 'native_file.dart';
import 'sending_status.dart';

part 'attachment.g.dart';

/// Attachment of a [ChatItem].
abstract class Attachment extends HiveObject {
  Attachment(
    this.id,
    this.original,
    this.filename,
  );

  /// Unique ID of this [Attachment].
  @HiveField(0)
  AttachmentId id;

  /// Original [StorageFile] representing this [Attachment].
  @HiveField(1)
  StorageFile original;

  /// Uploaded file's name.
  @HiveField(2)
  String filename;

  /// [Downloading] of this [Attachment].
  Rx<Downloading?> downloading = Rx<Downloading?>(null);

  /// Indicates whether this [Attachment] is downloading.
  bool get isDownloading => downloadStatus == DownloadStatus.inProgress;

  /// Return [DownloadStatus] of this [Attachment].
  DownloadStatus get downloadStatus =>
      downloading.value?.status.value ?? DownloadStatus.notStarted;

  /// Initializes this [Attachment].
  Future<void> init({void Function()? onSave});

  /// Disposes this [Attachment].
  void dispose();
}

/// Image [Attachment].
@HiveType(typeId: ModelTypeId.imageAttachment)
class ImageAttachment extends Attachment {
  ImageAttachment({
    required AttachmentId id,
    required StorageFile original,
    required String filename,
    required this.big,
    required this.medium,
    required this.small,
  }) : super(id, original, filename);

  /// Big [ImageAttachment]'s view image [StorageFile] of `400px`x`400px` size.
  @HiveField(3)
  StorageFile big;

  /// Medium [ImageAttachment]'s view image [StorageFile] of `200px`x`200px`
  /// size.
  @HiveField(4)
  StorageFile medium;

  /// Small [ImageAttachment]'s view image [StorageFile] of `30px`x`30px` size.
  @HiveField(5)
  StorageFile small;

  /// [StreamSubscription] for the [FileService.downloads] changes.
  StreamSubscription? _downloadsSubscription;

  @override
  Future<void> init({void Function()? onSave}) async {
    if (original.checksum != null) {
      downloading.value = FileService.downloads.firstWhereOrNull((e) {
        return e.checksum == original.checksum;
      });
    }

    if (downloading.value == null) {
      _downloadsSubscription = FileService.downloads.changes.listen((e) {
        switch (e.op) {
          case OperationKind.added:
            if (e.element.checksum == original.checksum) {
              downloading.value = e.element;
            }
            break;

          case OperationKind.removed:
            // No-op.
            break;

          case OperationKind.updated:
            // No-op.
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    _downloadsSubscription?.cancel();
  }
}

/// Plain file [Attachment].
@HiveType(typeId: ModelTypeId.fileAttachment)
class FileAttachment extends Attachment {
  FileAttachment({
    required AttachmentId id,
    required StorageFile original,
    required String filename,
  }) : super(id, original, filename);

  /// Path to the downloaded [FileAttachment] in the local filesystem.
  @HiveField(3)
  String? path;

  /// Callback, called when the [path] is changed.
  void Function()? onSave;

  /// Indicator whether this [FileAttachment] has already been [init]ialized.
  bool _initialized = false;

  /// Indicator whether this [FileAttachment] is downloaded.
  final RxBool _downloaded = RxBool(false);

  /// Indicates whether this [FileAttachment] is downloading.
  @override
  bool get isDownloading => downloadStatus == DownloadStatus.inProgress;

  /// [StreamSubscription] for the [FileService.downloads] changes.
  StreamSubscription? _downloadsSubscription;

  /// [StreamSubscription] for the [Downloading.status] changes.
  StreamSubscription? _statusSubscription;

  @override
  DownloadStatus get downloadStatus =>
      downloading.value?.status.value ??
      (_downloaded.value
          ? DownloadStatus.isFinished
          : DownloadStatus.notStarted);

  @override
  Future<void> init({void Function()? onSave}) async {
    if (_initialized) {
      return;
    }

    this.onSave = onSave;

    _initialized = true;

    if (original.checksum != null) {
      downloading.value = FileService.downloads.firstWhereOrNull((e) {
        return e.checksum == original.checksum;
      });
      _listenStatus();
    }

    if (downloading.value == null) {
      _downloadsSubscription = FileService.downloads.changes.listen((e) {
        switch (e.op) {
          case OperationKind.added:
            if (e.element.checksum == original.checksum) {
              downloading.value = e.element;
              _listenStatus();
            }
            break;

          case OperationKind.removed:
            // No-op.
            break;

          case OperationKind.updated:
            // No-op.
            break;
        }
      });
    } else if (downloading.value!.status.value == DownloadStatus.isFinished) {
      path = downloading.value!.file?.path;
      onSave?.call();
      _downloaded.value = true;
    }

    if (path != null) {
      File file = File(path!);
      if (await file.exists() && await file.length() == original.size) {
        _downloaded.value = true;
        return;
      }
    }

    File? file = await PlatformUtils.fileExists(
      filename,
      size: original.size,
      url: original.url,
    );

    if (file != null) {
      path = file.path;
      onSave?.call();
      _downloaded.value = true;
    } else {
      if (path != null) {
        path = null;
        onSave?.call();
      }
    }
  }

  @override
  void dispose() {
    _downloadsSubscription?.cancel();
    _statusSubscription?.cancel();
  }

  /// Downloads this [FileAttachment].
  Future<void> download() async {
    try {
      if (downloading.value == null) {
        downloading.value = FileService.download(
          original.url,
          original.checksum,
          filename,
          original.size,
        );
        _listenStatus();
      } else {
        downloading.value!.start(original.url);
      }

      File? file = await downloading.value!.future;

      if (file == null) {
        path = null;
      } else {
        _downloaded.value = true;
        path = file.path;
        onSave?.call();
      }
    } catch (_) {
      path = null;

      rethrow;
    }
  }

  /// Opens this [FileAttachment], if downloaded, or otherwise returns `false`.
  Future<bool> open() async {
    if (path != null) {
      File file = File(path!);

      if (await file.exists() && await file.length() == original.size) {
        await OpenFile.open(path!);
        return true;
      } else {
        path = null;
        onSave?.call();
      }
    }

    return false;
  }

  /// Cancels the downloading of this [FileAttachment].
  void cancelDownload() {
    try {
      downloading.value?.cancel();
    } on DioError catch (e) {
      if (e.type != DioErrorType.cancel) {
        rethrow;
      }
    }
  }

  /// Listens the [downloading] status updates.
  void _listenStatus() {
    _statusSubscription = downloading.value?.status.listen((status) {
      if (status == DownloadStatus.isFinished) {
        String? filePath = downloading.value?.file?.path;
        if (filePath != null && filePath != path) {
          path = filePath;
          onSave?.call();
        }
      }
    });
  }
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
          StorageFile(relativeRef: '', size: file.size),
          file.name,
        );

  /// [NativeFile] representing this [LocalAttachment].
  @HiveField(3)
  NativeFile file;

  /// [SendingStatus] of this [LocalAttachment].
  final Rx<SendingStatus> status;

  /// Upload progress of this [LocalAttachment].
  final Rx<double> progress = Rx(0);

  /// [Completer] resolving once this [LocalAttachment]'s uploading is finished.
  final Rx<Completer<Attachment>?> upload = Rx<Completer<Attachment>?>(null);

  /// [Completer] resolving once this [LocalAttachment]'s reading is finished.
  final Rx<Completer<void>?> read = Rx<Completer<void>?>(null);

  @override
  Future<void> init({void Function()? onSave}) async {
    // No-op.
  }

  @override
  void dispose() {
    // No-op.
  }
}

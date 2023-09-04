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
import '/ui/worker/cache.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import 'file.dart';
import 'native_file.dart';
import 'sending_status.dart';

part 'attachment.g.dart';

/// Attachment of a [ChatItem].
abstract class Attachment extends HiveObject {
  Attachment({
    required this.id,
    required this.original,
    required this.filename,
  });

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
    required super.id,
    required super.original,
    required super.filename,
    required this.big,
    required this.medium,
    required this.small,
  });

  /// Big view [ImageFile] of this [ImageAttachment], scaled proportionally to
  /// `800px` of its maximum dimension (either width or height).
  @HiveField(3)
  ImageFile big;

  /// Medium view [ImageFile] of this [ImageAttachment], scaled proportionally
  /// to `200px` of its maximum dimension (either width or height).
  @HiveField(4)
  ImageFile medium;

  /// Small view [ImageFile] of this [ImageAttachment], scaled proportionally to
  /// `30px` of its maximum dimension (either width or height).
  @HiveField(5)
  ImageFile small;

  /// [StreamSubscription] for the [CacheWorker.downloads] changes updating the
  /// [downloading].
  StreamSubscription? _downloadsSubscription;

  @override
  Future<void> init({void Function()? onSave}) async {
    if (original.checksum != null) {
      downloading.value = CacheWorker.instance.downloads[original.checksum];
    }

    if (downloading.value == null) {
      _downloadsSubscription =
          CacheWorker.instance.downloads.changes.listen((e) {
        switch (e.op) {
          case OperationKind.added:
            if (original.checksum != null && e.key == original.checksum) {
              downloading.value = e.value;
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
    required super.id,
    required super.original,
    required super.filename,
  });

  /// Path to the downloaded [FileAttachment] in the local filesystem.
  @HiveField(3)
  String? path;

  /// Callback, called to save this [FileAttachment] to local storage.
  void Function()? onSave;

  /// Indicator whether this [FileAttachment] has already been [init]ialized.
  bool _initialized = false;

  /// [StreamSubscription] for the [CacheWorker.downloads] changes updating the
  /// [downloading].
  StreamSubscription? _downloadsSubscription;

  /// [StreamSubscription] for the [Downloading.status] changes.
  StreamSubscription? _statusSubscription;

  @override
  Future<void> init({void Function()? onSave}) async {
    if (_initialized) {
      return;
    }

    this.onSave = onSave;

    _initialized = true;

    if (original.checksum != null) {
      downloading.value = CacheWorker.instance.downloads[original.checksum];
      _listenStatus();
    }

    if (downloading.value == null) {
      _downloadsSubscription =
          CacheWorker.instance.downloads.changes.listen((e) {
        switch (e.op) {
          case OperationKind.added:
            if (original.checksum != null && e.key == original.checksum) {
              downloading.value = e.value;
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
    }

    if (path != null) {
      File file = File(path!);
      if (await file.exists() && await file.length() == original.size) {
        downloading.value = Downloading.completed(
          original.checksum,
          filename,
          original.size,
          path!,
        );

        if (original.checksum != null) {
          CacheWorker.instance.downloads[original.checksum!] =
              downloading.value!;
        }
      }
    }

    if (downloading.value == null) {
      File? file = await PlatformUtils.fileExists(
        filename,
        size: original.size,
        url: original.url,
      );

      if (file != null) {
        path = file.path;
        downloading.value = Downloading.completed(
          original.checksum,
          filename,
          original.size,
          path!,
        );

        if (original.checksum != null) {
          CacheWorker.instance.downloads[original.checksum!] =
              downloading.value!;
        }

        onSave?.call();
      } else {
        if (path != null) {
          path = null;
          onSave?.call();
        }
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
        downloading.value = CacheWorker.instance.download(
          original.url,
          filename,
          original.size,
          checksum: original.checksum,
        );
        _listenStatus();
      } else {
        downloading.value!.start(original.url);
      }

      File? file = await downloading.value!.future;

      if (file == null) {
        path = null;
      } else {
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

  /// Cancels the [downloading] of this [FileAttachment].
  void cancelDownload() {
    try {
      downloading.value?.cancel();
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
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
          id: AttachmentId.local(),
          original: ImageFile(relativeRef: '', size: file.size),
          filename: file.name,
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

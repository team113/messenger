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

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../model_type_id.dart';
import '/ui/worker/cache.dart';
import '/util/new_type.dart';
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
  Downloading? get downloading =>
      CacheWorker.instance.downloads[original.checksum];

  /// Indicates whether this [Attachment] is downloading.
  bool get isDownloading => downloadStatus == DownloadStatus.inProgress;

  /// Return [DownloadStatus] of this [Attachment].
  DownloadStatus get downloadStatus =>
      downloading?.status.value ?? DownloadStatus.notStarted;
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
}

/// Plain file [Attachment].
@HiveType(typeId: ModelTypeId.fileAttachment)
class FileAttachment extends Attachment {
  FileAttachment({
    required super.id,
    required super.original,
    required super.filename,
  });

  /// Indicator whether this [FileAttachment] has already been [init]ialized.
  bool _initialized = false;

  /// Initializes this [FileAttachment].
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    await CacheWorker.instance.checkDownloaded(
      filename: filename,
      checksum: original.checksum,
      size: original.size,
      url: original.url,
    );
  }

  /// Downloads this [FileAttachment].
  Future<void> download() async {
    CacheWorker.instance.download(
      original.url,
      filename,
      original.size,
      checksum: original.checksum,
    );
  }

  /// Opens this [FileAttachment], if downloaded, or otherwise returns `false`.
  Future<bool> open() =>
      CacheWorker.instance.open(original.checksum, original.size);

  /// Cancels the [downloading] of this [FileAttachment].
  void cancelDownload() => downloading?.cancel();
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
}

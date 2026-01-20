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
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import '/ui/worker/cache.dart';
import '/util/new_type.dart';
import '/util/platform_utils.dart';
import 'file.dart';
import 'native_file.dart';
import 'sending_status.dart';

part 'attachment.g.dart';

/// Attachment of a [ChatItem].
abstract class Attachment {
  Attachment({
    required this.id,
    required this.original,
    required this.filename,
  });

  /// Constructs an [Attachment] from the provided [json].
  factory Attachment.fromJson(Map<String, dynamic> json) =>
      switch (json['runtimeType']) {
        'ImageAttachment' => ImageAttachment.fromJson(json),
        'FileAttachment' => FileAttachment.fromJson(json),
        'LocalAttachment' => LocalAttachment.fromJson(json),
        _ => throw UnimplementedError(json['runtimeType']),
      };

  /// Unique ID of this [Attachment].
  AttachmentId id;

  /// Original [StorageFile] representing this [Attachment].
  StorageFile original;

  /// Uploaded file's name.
  String filename;

  /// Returns the [Downloading] of this [Attachment], if any.
  Downloading? get downloading =>
      CacheWorker.instance.downloads[original.checksum];

  /// Indicates whether downloading of this [Attachment] is in progress.
  bool get isDownloading => downloadStatus == DownloadStatus.inProgress;

  /// Returns [DownloadStatus] of this [Attachment].
  DownloadStatus get downloadStatus =>
      downloading?.status.value ?? DownloadStatus.notStarted;

  /// Returns a [Map] representing this [Attachment].
  Map<String, dynamic> toJson() => switch (runtimeType) {
    const (ImageAttachment) => (this as ImageAttachment).toJson(),
    const (FileAttachment) => (this as FileAttachment).toJson(),
    const (LocalAttachment) => (this as LocalAttachment).toJson(),
    _ => throw UnimplementedError(runtimeType.toString()),
  };
}

/// Image [Attachment].
@JsonSerializable()
class ImageAttachment extends Attachment {
  ImageAttachment({
    required super.id,
    required super.original,
    required super.filename,
    required this.big,
    required this.medium,
    required this.small,
  });

  /// Constructs a [ImageAttachment] from the provided [json].
  factory ImageAttachment.fromJson(Map<String, dynamic> json) =>
      _$ImageAttachmentFromJson(json);

  /// Big view [ImageFile] of this [ImageAttachment], scaled proportionally to
  /// `800px` of its maximum dimension (either width or height).
  ImageFile big;

  /// Medium view [ImageFile] of this [ImageAttachment], scaled proportionally
  /// to `200px` of its maximum dimension (either width or height).
  ImageFile medium;

  /// Small view [ImageFile] of this [ImageAttachment], scaled proportionally to
  /// `30px` of its maximum dimension (either width or height).
  ImageFile small;

  /// Returns a [Map] representing this [ImageAttachment].
  @override
  Map<String, dynamic> toJson() =>
      _$ImageAttachmentToJson(this)..['runtimeType'] = 'ImageAttachment';
}

/// Plain file [Attachment].
@JsonSerializable()
class FileAttachment extends Attachment {
  FileAttachment({
    required super.id,
    required super.original,
    required super.filename,
  });

  /// Constructs a [FileAttachment] from the provided [json].
  factory FileAttachment.fromJson(Map<String, dynamic> json) =>
      _$FileAttachmentFromJson(json);

  /// Indicator whether this [FileAttachment] has already been [init]ialized.
  bool _initialized = false;

  /// Indicates whether this [FileAttachment] represents a video.
  bool get isVideo {
    final String file = filename.toLowerCase();
    return file.endsWith('.mp4') ||
        file.endsWith('.mov') ||
        file.endsWith('.webm') ||
        file.endsWith('.mkv') ||
        file.endsWith('.flv') ||
        file.endsWith('.3gp');
  }

  /// Initializes this [FileAttachment].
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    if (!PlatformUtils.isWeb) {
      await CacheWorker.instance.checkDownloaded(
        filename: filename,
        checksum: original.checksum,
        size: original.size,
        url: original.url,
      );
    }
  }

  /// Downloads this [FileAttachment].
  Future<File?>? download() => CacheWorker.instance
      .download(
        original.url,
        filename,
        original.size,
        checksum: original.checksum,
      )
      .future;

  /// Opens this [FileAttachment], if downloaded, or otherwise returns `false`.
  Future<bool> open() =>
      CacheWorker.instance.open(original.checksum, original.size);

  /// Cancels the [downloading] of this [FileAttachment].
  void cancelDownload() => downloading?.cancel();

  /// Returns a [Map] representing this [FileAttachment].
  @override
  Map<String, dynamic> toJson() =>
      _$FileAttachmentToJson(this)..['runtimeType'] = 'FileAttachment';

  @override
  String toString() =>
      'FileAttachment(id: $id, size: ${original.size}, filename: $filename, downloading: $downloading)';
}

/// Unique ID of an [Attachment].
class AttachmentId extends NewType<String> {
  const AttachmentId(super.val);

  /// Constructs a dummy [AttachmentId].
  factory AttachmentId.local() => AttachmentId('local_${const Uuid().v4()}');

  /// Constructs a [AttachmentId] from the provided [val].
  factory AttachmentId.fromJson(String val) = AttachmentId;

  /// Returns a [String] representing this [AttachmentId].
  String toJson() => val;
}

/// [Attachment] stored in a [NativeFile] locally.
@JsonSerializable()
class LocalAttachment extends Attachment {
  LocalAttachment(this.file, {SendingStatus status = SendingStatus.error})
    : status = Rx(status),
      super(
        id: AttachmentId.local(),
        original: ImageFile(
          relativeRef: '',
          size: file.size,
          width: file.dimensions.value?.width.round(),
          height: file.dimensions.value?.height.round(),
        ),
        filename: file.name,
      );

  /// Constructs a [LocalAttachment] from the provided [json].
  factory LocalAttachment.fromJson(Map<String, dynamic> json) =>
      _$LocalAttachmentFromJson(json);

  /// [NativeFile] representing this [LocalAttachment].
  NativeFile file;

  /// [SendingStatus] of this [LocalAttachment].
  @JsonKey(toJson: SendingStatusJson.toJson)
  final Rx<SendingStatus> status;

  /// [CancelToken] used to cancel the uploading of this [LocalAttachment].
  @JsonKey(includeToJson: false, includeFromJson: false)
  final CancelToken cancelToken = CancelToken();

  /// Upload progress of this [LocalAttachment].
  final Rx<double> progress = Rx(0);

  /// [Completer] resolving once this [LocalAttachment]'s uploading is finished.
  final Rx<Completer<Attachment?>?> upload = Rx<Completer<Attachment?>?>(null);

  /// [Completer] resolving once this [LocalAttachment]'s reading is finished.
  final Rx<Completer<void>?> read = Rx<Completer<void>?>(null);

  /// Indicator whether the [upload] was canceled.
  bool get isCanceled => cancelToken.isCancelled;

  /// Cancels the uploading of this [LocalAttachment].
  void cancelUpload() => cancelToken.cancel();

  /// Returns a [Map] representing this [LocalAttachment].
  @override
  Map<String, dynamic> toJson() =>
      _$LocalAttachmentToJson(this)..['runtimeType'] = 'LocalAttachment';
}

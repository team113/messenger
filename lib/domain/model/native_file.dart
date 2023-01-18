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

import 'dart:typed_data';

import 'package:async/async.dart' show StreamGroup, StreamQueue;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:mutex/mutex.dart';

import '../model_type_id.dart';
import '/util/mime.dart';
import '/util/platform_utils.dart';

/// Native file representation.
class NativeFile {
  NativeFile({
    required this.name,
    required this.size,
    this.path,
    required this.bytes,
    Stream<List<int>>? stream,
    this.mime,
  }) : _readStream = stream {
    // If possible, determine the `MIME` type right away.
    if (mime == null) {
      if (path != null) {
        var type = lookupMimeType(path!);
        if (type != null) {
          mime = MediaType.parse(type);
        }
      } else if (bytes.value != null) {
        var type = lookupMimeType(name, headerBytes: bytes.value);
        if (type != null) {
          mime = MediaType.parse(type);
        }
      }
    }
  }

  /// Constructs a [NativeFile] from a [PlatformFile].
  factory NativeFile.fromPlatformFile(PlatformFile file) => NativeFile(
        name: file.name,
        size: file.size,
        path: PlatformUtils.isWeb ? null : file.path,
        bytes: Rx(file.bytes),
        stream: file.readStream?.asBroadcastStream(),
      );

  /// Constructs a [NativeFile] from an [XFile].
  factory NativeFile.fromXFile(XFile file, int size) => NativeFile(
        name: file.name,
        size: size,
        path: PlatformUtils.isWeb ? null : file.path,
        stream: file.openRead().asBroadcastStream(),
        bytes: Rx(null),
      );

  /// Absolute path for a cached copy of this file.
  @HiveField(0)
  final String? path;

  /// File name including its extension.
  @HiveField(1)
  final String name;

  /// Byte data of this file.
  @HiveField(2)
  Rx<Uint8List?> bytes;

  /// Size of this file in bytes.
  @HiveField(3)
  final int size;

  /// [MediaType] of this file.
  ///
  /// __Note:__ To ensure [MediaType] is correct, invoke
  ///           [ensureCorrectMediaType] before accessing this field.
  @HiveField(4)
  MediaType? mime;

  /// [Mutex] for synchronized access to the [readFile].
  final Mutex _readGuard = Mutex();

  /// Content of this file as a stream.
  Stream<List<int>>? _readStream;

  /// Merged stream of [bytes] and [_readStream] representing the whole file.
  Stream<List<int>>? _mergedStream;

  /// Returns an extension of this file.
  String get extension => name.split('.').last;

  /// Indicates whether this file represents an image or not.
  bool get isImage {
    // Best effort if [mime] is `null`.
    if (mime == null) {
      return [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'jfif',
        'svg',
        'webp',
      ].contains(extension.toLowerCase());
    }

    return mime?.type == 'image';
  }

  /// Indicates whether this file represents an SVG or not.
  bool get isSvg {
    // Best effort if [mime] is `null`.
    if (mime == null) {
      return extension == 'svg';
    }

    return mime?.subtype == 'svg+xml';
  }

  /// Indicates whether this file represents a video or not.
  bool get isVideo {
    // Best effort if [mime] is `null`.
    if (mime == null) {
      return [
        'mp4',
        'mov',
        'webm',
        'mkv',
        'flv',
        '3gp',
      ].contains(extension.toLowerCase());
    }

    return mime?.type == 'video';
  }

  /// Returns contents of this file as a broadcast [Stream].
  ///
  /// Once read, it cannot be rewinded.
  Stream<List<int>>? get stream {
    if (_readStream == null) return null;

    _mergedStream ??= StreamGroup.mergeBroadcast([
      if (bytes.value != null) _streamOfBytes(),
      _readStream!,
    ]);

    return _mergedStream;
  }

  /// Ensures [mime] is correctly assigned.
  ///
  /// Tries to determine the [mime] type by reading the [stream].
  Future<void> ensureCorrectMediaType() {
    if (mime == null) {
      if (_readStream != null) {
        return Future(() async {
          bytes.value = Uint8List.fromList(await _readStream!.first);
          var type =
              MimeResolver.lookup(path ?? name, headerBytes: bytes.value);
          if (type != null) {
            mime = MediaType.parse(type);
          }
        });
      }
    }

    return Future.sync(() => null);
  }

  /// Reads this file from its [stream] and returns its [bytes].
  ///
  /// __Note:__ Be sure not to read the [stream] while this method executes.
  Future<Uint8List?> readFile() {
    return _readGuard.protect(() async {
      var content = stream;
      if (content != null) {
        List<int> data = [];

        StreamQueue queue = StreamQueue(content);
        while (await queue.hasNext) {
          data.addAll(await queue.next);
        }

        bytes.value = Uint8List.fromList(data);
        _readStream = null;
      }

      return bytes.value;
    });
  }

  /// Constructs a [Stream] from the [bytes].
  Stream<List<int>> _streamOfBytes() async* {
    yield bytes.value!.toList();
  }
}

/// [Hive] adapter for a [MediaType].
class MediaTypeAdapter extends TypeAdapter<MediaType> {
  @override
  int get typeId => ModelTypeId.mediaType;

  @override
  MediaType read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaType(
      fields[0] as String,
      fields[1] as String,
      (fields[2] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MediaType obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.subtype)
      ..writeByte(2)
      ..write(obj.parameters);
  }
}

/// [Hive] adapter for a [Rx<Uint8List?>].
class BytesRxAdapter extends TypeAdapter<Rx<Uint8List?>> {
  @override
  int get typeId => ModelTypeId.reactiveBytes;

  @override
  Rx<Uint8List?> read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Rx(fields[0] as Uint8List?);
  }

  @override
  void write(BinaryWriter writer, Rx<Uint8List?> obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.value);
  }
}

class NativeFileAdapter extends TypeAdapter<NativeFile> {
  @override
  final int typeId = ModelTypeId.nativeFile;

  @override
  NativeFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NativeFile(
      name: fields[1] as String,
      size: fields[3] as int,
      path: fields[0] as String?,
      bytes: fields[2] as Rx<Uint8List?>,
      mime: fields[4] as MediaType?,
    );
  }

  @override
  void write(BinaryWriter writer, NativeFile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.path)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.bytes)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.mime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is NativeFileAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}


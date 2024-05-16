// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'dart:ui';

import 'package:async/async.dart' show StreamGroup, StreamQueue;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mime/mime.dart';
import 'package:mutex/mutex.dart';

import '../model_type_id.dart';
import '/util/mime.dart';
import '/util/platform_utils.dart';

part 'native_file.g.dart';

/// Native file representation.
@JsonSerializable()
class NativeFile {
  NativeFile({
    required this.name,
    required this.size,
    this.path,
    Uint8List? bytes,
    Stream<List<int>>? stream,
    this.mime,
    Size? dimensions,
  })  : bytes = Rx(bytes),
        dimensions = Rx(dimensions),
        _readStream = stream {
    // If possible, determine the `MIME` type right away.
    if (mime == null) {
      if (path != null) {
        var type = lookupMimeType(path!);
        if (type != null) {
          mime = MediaType.parse(type);
        }
      } else if (bytes != null) {
        var type = lookupMimeType(name, headerBytes: bytes);
        if (type != null) {
          mime = MediaType.parse(type);
        }
      }
    }

    if (bytes != null) {
      _determineDimension();
    }
  }

  /// Constructs a [NativeFile] from a [PlatformFile].
  factory NativeFile.fromPlatformFile(PlatformFile file) => NativeFile(
        name: file.name,
        size: file.size,
        path: PlatformUtils.isWeb ? null : file.path,
        bytes: file.bytes,
        stream: file.readStream?.asBroadcastStream(),
      );

  /// Constructs a [NativeFile] from an [XFile].
  factory NativeFile.fromXFile(XFile file, int size) => NativeFile(
        name: file.name,
        size: size,
        path: PlatformUtils.isWeb ? null : file.path,
        stream: file.openRead().asBroadcastStream(),
      );

  /// Constructs a [NativeFile] from the provided [json].
  factory NativeFile.fromJson(Map<String, dynamic> json) =>
      _$NativeFileFromJson(json);

  /// Absolute path for a cached copy of this file.
  final String? path;

  /// File name including its extension.
  final String name;

  /// Byte data of this file.
  @JsonKey(fromJson: _RxUint8List.fromValue, toJson: _RxUint8List.toValue)
  final Rx<Uint8List?> bytes;

  /// Size of this file in bytes.
  final int size;

  /// [MediaType] of this file.
  ///
  /// __Note:__ To ensure [MediaType] is correct, invoke
  ///           [ensureCorrectMediaType] before accessing this field.
  @JsonKey(fromJson: _MediaType.fromValue, toJson: _MediaType.toValue)
  MediaType? mime;

  /// [Size] of the image this [NativeFile] represents, if [isImage].
  @JsonKey(fromJson: _RxSize.fromValue, toJson: _RxSize.toValue)
  final Rx<Size?> dimensions;

  /// [Mutex] for synchronized access to the [readFile].
  final Mutex _readGuard = Mutex();

  /// Content of this file as a stream.
  @JsonKey(fromJson: _StreamListInt.fromValue, toJson: _StreamListInt.toValue)
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
  @JsonKey(fromJson: _StreamListInt.fromValue, toJson: _StreamListInt.toValue)
  Stream<List<int>>? get stream {
    if (_readStream == null) return null;

    _mergedStream ??= StreamGroup.mergeBroadcast([
      if (bytes.value != null) _streamOfBytes(),
      _readStream!,
    ]);

    return _mergedStream;
  }

  /// Returns a [Map] representing this [NativeFile].
  Map<String, dynamic> toJson() => _$NativeFileToJson(this);

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

      await _determineDimension();

      return bytes.value;
    });
  }

  /// Determines the [dimensions].
  Future<void> _determineDimension() async {
    // Decode the file, if it [isImage].
    //
    // Throws an error, if decoding fails.
    if (dimensions.value == null && isImage && bytes.value != null) {
      // TODO: Validate SVGs and retrieve its width and height.
      if (!isSvg) {
        final decoded = await instantiateImageCodec(bytes.value!);
        final frame = await decoded.getNextFrame();
        dimensions.value = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      }
    }
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
    return MediaType(
      reader.read() as String,
      reader.read() as String,
      (reader.read() as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MediaType obj) {
    writer
      ..write(obj.type)
      ..write(obj.subtype)
      ..write(obj.parameters);
  }
}

/// [Hive] adapter for a [NativeFile].
class NativeFileAdapter extends TypeAdapter<NativeFile> {
  @override
  final int typeId = ModelTypeId.nativeFile;

  @override
  NativeFile read(BinaryReader reader) {
    return NativeFile(
      path: reader.read() as String?,
      name: reader.read() as String,
      bytes: reader.read() as Uint8List?,
      size: reader.read() as int,
      mime: reader.read() as MediaType?,
    );
  }

  @override
  void write(BinaryWriter writer, NativeFile obj) {
    writer
      ..write(obj.path)
      ..write(obj.name)
      ..write(obj.bytes.value)
      ..write(obj.size)
      ..write(obj.mime);
  }
}

extension _RxUint8List on Rx {
  static Rx<Uint8List?> fromValue(Uint8List? val) => Rx(val);
  static Uint8List? toValue(Rx<Uint8List?> val) => val.value;
}

extension _RxSize on Rx {
  static Rx<Size?> fromValue(Size? val) => Rx(val);
  static Size? toValue(Rx<Size?> val) => val.value;
}

extension _StreamListInt on Stream {
  static Stream<List<int>>? fromValue(String? val) => null;
  static String? toValue(Stream<List<int>>? val) => null;
}

extension _MediaType on MediaType {
  static MediaType? fromValue(String? val) =>
      val == null ? null : MediaType.parse(val);
  static String? toValue(MediaType? val) => val?.toString();
}

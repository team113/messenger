// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:async/async.dart' show StreamGroup, StreamQueue;
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mime/mime.dart';
import 'package:mutex/mutex.dart';

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
    ui.Size? dimensions,
  }) : bytes = Rx(bytes),
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
      _$NativeFileFromJson(json)
        ..dimensions.value = _SizeExtension.fromJson(json['dimensions'])
        ..bytes.value = _Uint8ListExtension.fromJson(json['bytes']);

  /// Absolute path for a cached copy of this file.
  final String? path;

  /// File name including its extension.
  final String name;

  /// Byte data of this file.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Rx<ui.Size?> dimensions;

  /// [Mutex] for synchronized access to the [readFile].
  final Mutex _readGuard = Mutex();

  /// Content of this file as a stream.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Stream<List<int>>? _readStream;

  /// Merged stream of [bytes] and [_readStream] representing the whole file.
  Stream<List<int>>? _mergedStream;

  /// Returns the extensions of files considered to be images.
  static const List<String> images = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'jfif',
    'svg',
    'webp',
  ];

  /// Returns an extension of this file.
  String get extension => name.split('.').last;

  /// Indicates whether this file represents an image or not.
  bool get isImage {
    // Best effort if [mime] is `null`.
    if (mime == null) {
      return images.contains(extension.toLowerCase());
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
  @JsonKey(includeFromJson: false, includeToJson: false)
  Stream<List<int>>? get stream {
    if (_readStream == null) return null;

    _mergedStream ??= StreamGroup.mergeBroadcast([
      if (bytes.value != null) _streamOfBytes(),
      _readStream!,
    ]);

    return _mergedStream;
  }

  /// Returns a [Map] representing this [NativeFile].
  Map<String, dynamic> toJson() => _$NativeFileToJson(this)
    ..['dimensions'] = dimensions.value?.toJson()
    ..['bytes'] = bytes.value?.toJson();

  /// Ensures [mime] is correctly assigned.
  ///
  /// Tries to determine the [mime] type by reading the [stream].
  Future<void> ensureCorrectMediaType() {
    if (mime == null) {
      if (_readStream != null) {
        return Future(() async {
          bytes.value = Uint8List.fromList(await _readStream!.first);
          var type = MimeResolver.lookup(
            path ?? name,
            headerBytes: bytes.value,
          );
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

  /// Converts the [NativeFile] to a [MultipartFile].
  Future<dio.MultipartFile> toMultipartFile() async {
    final String filename = _resolveFilename();

    if (path != null) {
      return await dio.MultipartFile.fromFile(
        path!,
        filename: filename,
        contentType: mime,
      );
    }

    final Uint8List? byteData = bytes.value;
    if (byteData != null) {
      return dio.MultipartFile.fromStream(
        () => _chunkedStream(byteData),
        byteData.length,
        filename: filename,
        contentType: mime,
      );
    }

    if (stream != null) {
      return dio.MultipartFile.fromStream(
        () => stream!,
        size,
        filename: filename,
        contentType: mime,
      );
    }

    throw ArgumentError('At least stream, bytes or path should be specified.');
  }

  /// Returns a valid filename, using timestamp if the original name is empty.
  String _resolveFilename() {
    final String result = name.trim();
    if (result.isNotEmpty) return result;

    final int timestamp = DateTime.now().microsecondsSinceEpoch;
    return mime != null ? '$timestamp.${mime?.subtype}' : '$timestamp';
  }

  /// Creates a chunked stream from bytes to allow proper progress callbacks.
  Stream<List<int>> _chunkedStream(
    List<int> bytes, {
    int chunkSize = 64 * 1024,
  }) async* {
    for (int offset = 0; offset < bytes.length; offset += chunkSize) {
      final int end = (offset + chunkSize > bytes.length)
          ? bytes.length
          : offset + chunkSize;
      yield bytes.sublist(offset, end);
    }
  }

  /// Determines the [dimensions].
  Future<void> _determineDimension() async {
    // Decode the file, if it [isImage].
    //
    // Throws an error, if decoding fails.
    if (dimensions.value == null && isImage && bytes.value != null) {
      // TODO: Validate SVGs and retrieve its width and height.
      if (!isSvg) {
        final ui.Codec decoded = await ui.instantiateImageCodec(bytes.value!);
        final ui.FrameInfo frame = await decoded.getNextFrame();
        dimensions.value = ui.Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );

        // This object must be disposed by the recipient of the frame info.
        frame.image.dispose();
      }
    }
  }

  /// Constructs a [Stream] from the [bytes].
  Stream<List<int>> _streamOfBytes() async* {
    yield bytes.value!.toList();
  }
}

/// Extension adding methods to construct the [MediaType] to/from primitive
/// types.
///
/// Intended to be used as [JsonKey.toJson] and [JsonKey.fromJson] methods.
extension _MediaType on MediaType {
  /// Returns a [MediaType] constructed from the provided [val].
  static MediaType? fromValue(String? val) =>
      val == null ? null : MediaType.parse(val);

  /// Returns a [String] representing this [MediaType].
  static String? toValue(MediaType? val) => val?.toString();
}

/// Extension adding methods to construct the [Size] to/from primitive types.
///
/// Intended to be used as [JsonKey.toJson] and [JsonKey.fromJson] methods.
extension _SizeExtension on ui.Size {
  /// Returns a [Size] constructed from the provided [json].
  static ui.Size? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return ui.Size(json['width'] as double, json['height'] as double);
  }

  /// Returns a [String] representing this [Size].
  Map<String, dynamic> toJson() => {'width': width, 'height': height};
}

/// Extension adding methods to construct the [Uint8List] to/from primitive
/// types.
///
/// Intended to be used as [JsonKey.toJson] and [JsonKey.fromJson] methods.
extension _Uint8ListExtension on Uint8List {
  /// Returns a [Uint8List] constructed from the provided [val].
  static Uint8List? fromJson(String? val) {
    if (val == null) {
      return null;
    }

    return base64.decode(val);
  }

  /// Returns a [String] representing this [Uint8List].
  String toJson() => base64.encode(this);
}

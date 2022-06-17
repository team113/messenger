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

import 'dart:typed_data';

import 'package:async/async.dart' show StreamGroup;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '/util/mime.dart';
import '/util/platform_utils.dart';

/// Native file representation.
class NativeFile {
  NativeFile({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
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
      } else if (bytes != null) {
        var type = lookupMimeType(name, headerBytes: bytes);
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
        stream: file.readStream?.asBroadcastStream(),
        bytes: file.bytes,
        path: PlatformUtils.isWeb ? null : file.path,
      );

  /// Constructs a [NativeFile] from an [XFile].
  factory NativeFile.fromXFile(XFile file, int size) => NativeFile(
        size: size,
        name: file.name,
        path: file.path,
        stream: file.openRead(),
      );

  /// Absolute path for a cached copy of this file.
  final String? path;

  /// File name including its extension.
  final String name;

  /// Byte data of this file.
  Uint8List? bytes;

  /// Size of this file in bytes.
  final int size;

  /// [MediaType] of this file.
  ///
  /// __Note:__ To ensure [MediaType] is correct, invoke
  ///           [ensureCorrectMediaType] before accessing this field.
  MediaType? mime;

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

  /// Returns contents of this file as a broadcast [Stream].
  ///
  /// Once read, it cannot be rewinded.
  Stream<List<int>>? get stream {
    if (_readStream == null) return null;

    _mergedStream ??= StreamGroup.mergeBroadcast([
      if (bytes != null) _streamOfBytes(),
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
          bytes = Uint8List.fromList(await _readStream!.first);
          var type = MimeResolver.lookup(path ?? name, headerBytes: bytes);
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
  Future<Uint8List?> readFile() async {
    var content = stream;
    if (content != null) {
      Uint8List data = Uint8List.fromList(
        (await content.toList()).expand((e) => e).toList(),
      );

      bytes = data;
      _readStream = null;
    }

    return bytes;
  }

  /// Constructs a [Stream] from the [bytes].
  Stream<List<int>> _streamOfBytes() async* {
    yield bytes!.toList();
  }
}

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

import 'dart:async';

import 'package:dio/dio.dart';

import '/domain/model/native_file.dart';

/// Converts the [NativeFile] to a [MultipartFile].
Future<MultipartFile> multipartFromNativeFile(NativeFile file) =>
    file.toMultipartFile();

/// Extension adding a method to construct a [MultipartFile] from [NativeFile].
extension _NativeFileExtension on NativeFile {
  /// Converts the [NativeFile] to a [MultipartFile].
  Future<MultipartFile> toMultipartFile() async {
    final String filename = _resolveFilename();

    if (path != null) {
      return await MultipartFile.fromFile(
        path!,
        filename: filename,
        contentType: mime,
      );
    }

    final byteData = bytes.value;
    if (byteData != null) {
      return MultipartFile.fromStream(
        () => _chunkedStream(byteData),
        byteData.length,
        filename: filename,
        contentType: mime,
      );
    }

    if (stream != null) {
      return MultipartFile.fromStream(
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
    var result = name.trim();
    if (result.isNotEmpty) return result;

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return mime != null ? '$timestamp.${mime!.subtype}' : '$timestamp';
  }

  /// Creates a chunked stream from bytes to allow proper progress callbacks.
  Stream<List<int>> _chunkedStream(
    List<int> bytes, {
    int chunkSize = 64 * 1024,
  }) async* {
    for (int offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize > bytes.length)
          ? bytes.length
          : offset + chunkSize;
      yield bytes.sublist(offset, end);
    }
  }
}

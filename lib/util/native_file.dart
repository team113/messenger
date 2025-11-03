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

extension NativeFileExtension on NativeFile {
  Future<MultipartFile> toChatMultipartFile() async {
    String filename = name;

    if (filename.replaceAll(' ', '').isEmpty) {
      if (mime != null) {
        filename = '${DateTime.now().microsecondsSinceEpoch}.${mime!.subtype}';
      } else {
        filename = '${DateTime.now().microsecondsSinceEpoch}';
      }
    }

    if (path != null) {
      return await MultipartFile.fromFile(
        path!,
        filename: filename,
        contentType: mime,
      );
    } else if (bytes.value != null) {
      final bytes = this.bytes.value!;

      const int chunkSize = 64 * 1024;

      Stream<List<int>> createStream() async* {
        for (int offset = 0; offset < bytes.length; offset += chunkSize) {
          final end = (offset + chunkSize > bytes.length)
              ? bytes.length
              : offset + chunkSize;
          yield bytes.sublist(offset, end);
        }
      }

      return MultipartFile.fromStream(
        createStream,
        bytes.length,
        filename: filename,
        contentType: mime,
      );
    } else {
      throw ArgumentError(
        'At least stream, bytes or path should be specified.',
      );
    }
  }

  Future<MultipartFile> toMultipartFile() async {
    if (stream != null) {
      return MultipartFile.fromStream(
        () => stream!,
        size,
        filename: name,
        contentType: mime,
      );
    } else if (bytes.value != null) {
      return MultipartFile.fromBytes(
        bytes.value!,
        filename: name,
        contentType: mime,
      );
    } else if (path != null) {
      return await MultipartFile.fromFile(
        path!,
        filename: name,
        contentType: mime,
      );
    } else {
      throw ArgumentError(
        'At least stream, bytes or path should be specified.',
      );
    }
  }
}

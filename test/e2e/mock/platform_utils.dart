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
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/src/file_picker.dart';
import 'package:file_picker/src/file_picker_result.dart';
import 'package:get/get.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// Mocked [PlatformUtilsImpl] to use in the tests.
class PlatformUtilsMock extends PlatformUtilsImpl {
  /// [String] set in a mocked [Clipboard].
  String? clipboard;

  /// [FilePickerResult] completer to be awaited in [pickFiles].
  Completer<FilePickerResult>? filesCompleter;

  @override
  Future<bool> get isActive => Future.value(true);

  @override
  Stream<bool> get onActivityChanged => Stream.value(true);

  @override
  Future<File?> download(
    String url,
    String filename,
    int? size, {
    String? path,
    String? checksum,
    Function(int count, int total)? onReceiveProgress,
    CancelToken? cancelToken,
    bool temporary = false,
    int retries = 5,
  }) async {
    int total = 100;
    for (int count = 0; count <= total; count++) {
      if (cancelToken?.isCancelled == true) {
        return null;
      }
      await Future.delayed(50.milliseconds);
      onReceiveProgress?.call(count, total);
    }

    return File('test/path');
  }

  @override
  Future<void> copy({
    String? text,
    SimpleFileFormat? format,
    Uint8List? data,
  }) => Future.sync(() => clipboard = text);

  @override
  void keepActive([bool active = true]) {
    // No-op.
  }

  @override
  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    List<String>? allowedExtensions,
  }) async {
    filesCompleter ??= Completer();
    return await filesCompleter?.future;
  }
}

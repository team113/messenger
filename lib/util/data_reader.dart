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
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// Extension adding a method to construct a [PlatformFile] from [DataReader].
extension DropItemExtension on DataReader {
  /// Constructs the [PlatformFile] from this [DataReader].
  Future<PlatformFile?> asPlatformFile() {
    final Completer<PlatformFile?> completer = Completer<PlatformFile?>();
    final SimpleFileFormat? format = getFormats(
      Formats.standardFormats,
    ).whereType<SimpleFileFormat>().lastOrNull;

    getFile(format, (DataReaderFile file) async {
      try {
        // Read the file bytes asynchronously.
        final Uint8List bytes = await file.readAll();

        final PlatformFile platformFile = PlatformFile(
          name: file.fileName ?? '',
          size: file.fileSize ?? 0,
          bytes: bytes,
        );

        completer.complete(platformFile);
      } catch (error) {
        completer.completeError(error);
      }
    });

    return completer.future;
  }
}

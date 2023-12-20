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

import 'package:intl/intl.dart';

import '../domain/model/file.dart';
import '../ui/worker/cache.dart';
import 'mime.dart';

/// Extension adding an ability to generate filename.
extension GenerateNameExt on StorageFile {
  /// Generates filename for [StorageFile] (ex: '123456.jpg')
  Future<String> generateFilename() async {
    final name =
        checksum ?? DateFormat('yyyy_MM_dd_j_m_s').format(DateTime.now());

    // check mime type
    final CacheEntry cache =
        await CacheWorker.instance.get(url: url, checksum: checksum);
    final bytes = Uint8List.fromList(cache.bytes!
        .take(MimeResolver.resolver.magicNumbersMaxLength)
        .toList());
    var type = MimeResolver.lookup(url, headerBytes: bytes);

    final String? ext = (type == null) ? null : extensionFromMime(type);

    return (ext == null) ? name : '$name.$ext';
  }
}

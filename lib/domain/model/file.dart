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

import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import '../model_type_id.dart';
import '/config.dart';
import '/util/new_type.dart';

part 'file.g.dart';

/// File on a file storage.
abstract class StorageFile extends HiveObject {
  StorageFile({
    required this.relativeRef,
    this.checksum,
    this.size,
  });

  /// Relative reference to this [StorageFile] on a file storage.
  ///
  /// Prepend it with a file storage URL to obtain the full link to this
  /// [StorageFile].
  ///
  /// If `404` HTTP status code is returned while trying to download this
  /// [StorageFile] from a file storage, then the [StorageFile] is not ready
  /// yet. Back off, and retry again later.
  ///
  /// `403` HTTP status code, on the other hand, means that the link has been
  /// expired and this relative reference should be re-fetched to rebuild the
  /// link.
  @HiveField(0)
  final String relativeRef;

  /// SHA-256 checksum of this [StorageFile].
  ///
  /// May be `null` in case this [StorageFile] is not ready on a file storage
  /// yet. May be also computed, once this [StorageFile] is ready and
  /// successfully downloaded from a file storage.
  ///
  /// This checksum is especially useful to verify the integrity and
  /// authenticity of this [StorageFile], downloaded from a file storage.
  ///
  /// Also, this checksum may be useful as a key in a cache, allowing to store
  /// [StorageFile] in deduplicated manner.
  @HiveField(1)
  final String? checksum;

  /// Size of this [StorageFile] (in bytes).
  ///
  /// May be `null` in case this [StorageFile] is not ready on a file storage
  /// yet. May be also computed, once this [StorageFile] is ready and
  /// successfully downloaded from a file storage.
  @HiveField(2)
  final int? size;

  /// Returns an absolute URL to this [StorageFile] on a file storage.
  String get url => '${Config.files}$relativeRef';

  /// Returns the name of this [StorageFile].
  String get name {
    final basename = DateFormat('yyyy_MM_dd_H_m_s').format(DateTime.now());
    return [basename, _extension].nonNulls.join('.');
  }

  /// Returns the extension parsed from the [relativeRef], excluding the dot, if
  /// any.
  ///
  /// ```dart
  /// var file = StorageFile(relativeRef: 'http://site/.jpg');
  /// print(file._extension); // => 'jpg'
  ///
  /// var file = StorageFile(relativeRef: 'http://site/noExtension');
  /// print(file._extension); // => 'null'
  /// ```
  String? get _extension {
    final index = url.lastIndexOf('.');
    if (index < 0 || index + 1 >= url.length) {
      return null;
    }

    final result = url.substring(index + 1).toLowerCase();
    if (result.contains('/')) {
      return null;
    }

    return result;
  }
}

/// Plain-[StorageFile] on a file storage.
@HiveType(typeId: ModelTypeId.plainFile)
class PlainFile extends StorageFile {
  PlainFile({
    required super.relativeRef,
    super.checksum,
    super.size,
  });
}

/// Image-[StorageFile] on a file storage.
@HiveType(typeId: ModelTypeId.imageFile)
class ImageFile extends StorageFile {
  ImageFile({
    required super.relativeRef,
    super.checksum,
    super.size,
    this.width,
    this.height,
    this.thumbhash,
  });

  /// Width of this [ImageFile] in pixels.
  @HiveField(3)
  final int? width;

  /// Height of this [ImageFile] in pixels.
  @HiveField(4)
  final int? height;

  /// [ThumbHash] of this [ImageFile].
  @HiveField(5)
  final ThumbHash? thumbhash;
}

/// [Base64URL][1]-encoded [ThumbHash][2].
///
/// [1]: https://base64.guru/standards/base64url
/// [2]: https://evanw.github.io/thumbhash/
@HiveType(typeId: ModelTypeId.thumbhash)
class ThumbHash extends NewType<String> {
  const ThumbHash(super.val);
}

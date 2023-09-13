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

import 'package:mime/mime.dart';

/// Wrapper around [MimeTypeResolver] resolving MIME-types.
class MimeResolver {
  /// Lazily initialized [MimeTypeResolver] used to lookup and resolve
  /// MIME-types.
  static MimeTypeResolver? _resolver;

  /// Returns the inner [MimeTypeResolver].
  static MimeTypeResolver get resolver {
    if (_resolver == null) {
      _resolver = MimeTypeResolver();

      // TODO: Fill the resolver with more MIME-types.
      _resolver?.addMagicNumber(
        [0x00, 0x00, 0x00, 0x00, 0x6D, 0x6F, 0x6F, 0x76],
        'video/quicktime',
        mask: [0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF],
      );
    }

    return _resolver!;
  }

  /// Performs a MIME-type lookup and returns it, if any is determined.
  ///
  /// If [headerBytes] is present, a match for known magic-numbers will be
  /// performed first. This allows the correct MIME-type to be found, even
  /// though a file have been saved using the wrong file extension.
  static String? lookup(String path, {List<int>? headerBytes}) =>
      resolver.lookup(path, headerBytes: headerBytes);
}

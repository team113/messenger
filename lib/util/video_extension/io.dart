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

import 'package:crypto/crypto.dart';
import 'package:video_player/video_player.dart';

import '../platform_utils.dart';

/// Extension adding [VideoPlayerController] constructor from [Uint8List].
extension VideoPlayerControllerExt on VideoPlayerController {
  /// Creates a [VideoPlayerController] from the provided [bytes].
  static FutureOr<VideoPlayerController> bytes(
    Uint8List bytes, {
    String? checksum,
    VideoPlayerOptions? videoPlayerOptions,
  }) async {
    final String hash = checksum ?? sha256.convert(bytes).toString();

    final File file = File(
      '${(await PlatformUtils.temporaryDirectory).path}/$hash',
    );

    if (!file.existsSync() || file.lengthSync() != bytes.length) {
      file.writeAsBytesSync(bytes);
    }

    return VideoPlayerController.file(
      file,
      videoPlayerOptions: videoPlayerOptions,
    );
  }
}

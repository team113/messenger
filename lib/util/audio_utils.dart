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

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Global variable to access [AudioUtilsImpl].
///
/// May be reassigned to mock specific functionally.
// ignore: non_constant_identifier_names
AudioUtilsImpl AudioUtils = AudioUtilsImpl();

/// Helper providing direct access to media related resources like media
/// devices, media tracks, etc.
class AudioUtilsImpl {
  AudioPlayer? _player;

  /// Plays the provided [sound] once.
  Future<void> once(AudioSource sound) async {
    _player ??= AudioPlayer();

    await runZonedGuarded(
      () async => await _player?.play(
        sound.source,
        position: Duration.zero,
        mode: PlayerMode.lowLatency,
      ),
      (e, _) {
        if (!e.toString().contains('NotAllowedError')) {
          throw e;
        }
      },
    );
  }
}

enum AudioSourceKind { asset, file, url }

abstract class AudioSource {
  const AudioSource();

  factory AudioSource.asset(String asset) = AssetAudioSource;
  factory AudioSource.file(String file) = FileAudioSource;
  factory AudioSource.url(String url) = UrlAudioSource;

  AudioSourceKind get kind;
}

class AssetAudioSource extends AudioSource {
  const AssetAudioSource(this.asset);

  final String asset;

  @override
  AudioSourceKind get kind => AudioSourceKind.asset;
}

class FileAudioSource extends AudioSource {
  const FileAudioSource(this.file);

  final String file;

  @override
  AudioSourceKind get kind => AudioSourceKind.file;
}

class UrlAudioSource extends AudioSource {
  const UrlAudioSource(this.url);

  final String url;

  @override
  AudioSourceKind get kind => AudioSourceKind.url;
}

extension on AudioSource {
  Source get source => switch (kind) {
        AudioSourceKind.asset => AssetSource((this as AssetAudioSource).asset),
        AudioSourceKind.file =>
          DeviceFileSource((this as FileAudioSource).file),
        AudioSourceKind.url => UrlSource((this as UrlAudioSource).url),
      };
}

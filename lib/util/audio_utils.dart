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

import 'package:media_kit/media_kit.dart';

import 'log.dart';
import 'platform_utils.dart';

/// Global variable to access [AudioUtilsImpl].
///
/// May be reassigned to mock specific functionally.
// ignore: non_constant_identifier_names
AudioUtilsImpl AudioUtils = AudioUtilsImpl();

/// Helper providing direct access to audio playback related resources.
class AudioUtilsImpl {
  /// [Player] lazily initialized to play sounds [once].
  Player? _player;

  /// [StreamController]s of [AudioSource]s added in [play].
  final Map<AudioSource, StreamController<void>> _players = {};

  /// Ensures the underlying resources are initialized to reduce possible delays
  /// when playing [once].
  void ensureInitialized() {
    try {
      _player ??= Player();
    } catch (e) {
      // If [Player] isn't available on the current platform, this throws a
      // `null check operator used on a null value`.
      if (e is! TypeError) {
        Log.error('Failed to initialize `Player`: ${e.toString()}');
      }
    }
  }

  /// Plays the provided [sound] once.
  Future<void> once(AudioSource sound, {double? volume}) async {
    ensureInitialized();

    await _player?.open(sound.media);

    if (volume != null) {
      await _player?.setVolume(volume);
    }
  }

  /// Plays the provided [music] looped with the specified [fade].
  ///
  /// Stopping the [music] means canceling the returned [StreamSubscription].
  StreamSubscription<void> play(
    AudioSource music, {
    Duration fade = Duration.zero,
  }) {
    StreamController? controller = _players[music];
    StreamSubscription? position;

    if (controller == null) {
      Player? player;
      Timer? timer;

      controller = StreamController.broadcast(
        onListen: () async {
          try {
            player = Player();
          } catch (e) {
            // If [Player] isn't available on the current platform, this throws
            // a `null check operator used on a null value`.
            if (e is! TypeError) {
              Log.error('Failed to initialize `Player`: ${e.toString()}');
            }
          }

          await player?.open(music.media);

          // TODO: Wait for `media_kit` to improve [PlaylistMode.loop] in Web.
          if (PlatformUtils.isWeb) {
            position = player?.stream.completed.listen((e) async {
              await player?.seek(Duration.zero);
              await player?.play();
            });
          } else {
            await player?.setPlaylistMode(PlaylistMode.loop);
          }

          if (fade != Duration.zero) {
            await player?.setVolume(0);
            timer = Timer.periodic(
              Duration(microseconds: fade.inMicroseconds ~/ 10),
              (timer) async {
                if (timer.tick > 9) {
                  timer.cancel();
                } else {
                  await player?.setVolume(100 * (timer.tick + 1) / 10);
                }
              },
            );
          }
        },
        onCancel: () async {
          _players.remove(music);
          position?.cancel();
          timer?.cancel();

          Future<void>? dispose = player?.dispose();
          player = null;
          await dispose;
        },
      );

      _players[music] = controller;
    }

    return controller.stream.listen((_) {});
  }
}

/// Possible [AudioSource] kind.
enum AudioSourceKind { asset, file, url }

/// Source to play an audio stream from.
abstract class AudioSource {
  const AudioSource();

  /// Constructs an [AudioSource] from the provided [asset].
  factory AudioSource.asset(String asset) = AssetAudioSource;

  /// Constructs an [AudioSource] from the provided [file].
  factory AudioSource.file(String file) = FileAudioSource;

  /// Constructs an [AudioSource] from the provided [url].
  factory AudioSource.url(String url) = UrlAudioSource;

  /// Returns a [AudioSourceKind] of this [AudioSource].
  AudioSourceKind get kind;
}

/// [AudioSource] of the provided [asset].
class AssetAudioSource extends AudioSource {
  const AssetAudioSource(this.asset);

  /// Path to an asset to play audio from.
  final String asset;

  @override
  AudioSourceKind get kind => AudioSourceKind.asset;

  @override
  int get hashCode => asset.hashCode;

  @override
  bool operator ==(Object other) =>
      other is AssetAudioSource && other.asset == asset;
}

/// [AudioSource] of the provided [file].
class FileAudioSource extends AudioSource {
  const FileAudioSource(this.file);

  /// Path to a file to play audio from.
  final String file;

  @override
  AudioSourceKind get kind => AudioSourceKind.file;

  @override
  int get hashCode => file.hashCode;

  @override
  bool operator ==(Object other) =>
      other is FileAudioSource && other.file == file;
}

/// [AudioSource] of the provided [url].
class UrlAudioSource extends AudioSource {
  const UrlAudioSource(this.url);

  /// URL to play audio from.
  final String url;

  @override
  AudioSourceKind get kind => AudioSourceKind.url;

  @override
  int get hashCode => url.hashCode;

  @override
  bool operator ==(Object other) => other is UrlAudioSource && other.url == url;
}

/// Extension adding conversion from an [AudioSource] to a [Media].
extension on AudioSource {
  /// Returns a [Media] corresponding to this [AudioSource].
  Media get media => switch (kind) {
        AudioSourceKind.asset => Media(
            'asset:///assets/${PlatformUtils.isWeb ? 'assets/' : ''}${(this as AssetAudioSource).asset}',
          ),
        AudioSourceKind.file =>
          Media('file:///${(this as FileAudioSource).file}'),
        AudioSourceKind.url => Media((this as UrlAudioSource).url),
      };
}

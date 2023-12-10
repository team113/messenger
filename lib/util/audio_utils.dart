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


class PlayerController {
  late StreamController<void> _stream_controller;
  Player ?_player;
  Timer ?_timer;

  StreamSubscription<void> beginPlay({void Function(void) ?onData = null, dynamic Function() ?onDone = null}) {
    return _stream_controller.stream.listen(onData ?? (_) {}, onDone: onDone);
  }

  Stream<Duration> getPositionStream() {
    return _player!.stream.position;
  }

  Stream<Duration> getDurationStream() {
    return _player!.stream.duration;
  }

  void close() {
    _stream_controller.close();
  }

  void seek(double milliseconds) {
    _player?.seek(Duration(milliseconds: milliseconds.floor()));
  }
}

/// Helper providing direct access to audio playback related resources.
class AudioUtilsImpl {
  /// [Player] lazily initialized to play sounds [once].
  Player? _player;

  /// [StreamController]s of [AudioSource]s added in [play].
  final Map<AudioSource, PlayerController> _players = {};

  /// Ensures the underlying resources are initialized to reduce possible delays
  /// when playing [once].
  void ensureInitialized() {
    try {
      _player ??= Player();
    } catch (e) {
      // If [Player] isn't available on the current platform, this throws a
      // `null check operator used on a null value`.
      if (e is! TypeError) {
        Log.error(
          'Failed to initialize `Player`: ${e.toString()}',
          '$runtimeType',
        );
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

  StreamSubscription<void> play(
      AudioSource music, {
        Duration fade = Duration.zero,
        bool loop = true,
        bool stop_others = false,
      }) {
    var stream = createPlayStream(music, fade: fade, loop: loop, stop_others: stop_others);
    return stream.beginPlay();
  }

    /// Plays the provided [music] looped with the specified [fade].
  /// [loop] forces the [music] to loop. It is true by default.
  /// [stop_others] if true, stops other played streams. It is false by default.
  /// [onDone] optional onDone handler for returned StreamSubscription.
  /// Stopping the [music] means canceling the returned [StreamSubscription].
  PlayerController createPlayStream(
    AudioSource music, {
    Duration fade = Duration.zero,
    bool loop = true,
    bool stop_others = false,
  }) {
    PlayerController? controller = _players[music];
    StreamSubscription? position;

    if (stop_others) {
      _players.forEach((key, value) {
        if (key != music) {
          value.close();
        }
      });
    }

    if (controller == null || controller._player == null) {

      controller = PlayerController();

      var stream_controller = StreamController.broadcast(
        onListen: () async {
          try {
            controller?._player = Player();
          } catch (e) {
            // If [Player] isn't available on the current platform, this throws
            // a `null check operator used on a null value`.
            if (e is! TypeError) {
              Log.error(
                'Failed to initialize `Player`: ${e.toString()}',
                '$runtimeType',
              );
            }
          }

          await controller?._player?.open(music.media);

          // TODO: Wait for `media_kit` to improve [PlaylistMode.loop] in Web.
          if (loop) {
            if (PlatformUtils.isWeb) {
              position = controller?._player?.stream.completed.listen((e) async {
                await controller?._player?.seek(Duration.zero);
                await controller?._player?.play();
              });
            } else {
              await controller?._player?.setPlaylistMode(PlaylistMode.loop);
            }
          } else {
            controller?._player?.stream.completed.listen((e) {
              Future.delayed(const Duration(milliseconds: 500), ()
              {
                if (controller?._player != null && controller!._player!.state.completed) {
                  controller?.close();
                }
              });
            });
          }

          if (fade != Duration.zero) {
            await controller?._player?.setVolume(0);
            controller?._timer = Timer.periodic(
              Duration(microseconds: fade.inMicroseconds ~/ 10),
              (timer) async {
                if (timer.tick > 9) {
                  timer.cancel();
                } else {
                  await controller?._player?.setVolume(100 * (timer.tick + 1) / 10);
                }
              },
            );
          }

          // Put something into the stream to trigger onData at other side.
          // This is where listener may execute additional setup actions after player is started
          controller?._stream_controller.add(null);
        },
        onCancel: () async {
          _players.remove(music);
          position?.cancel();
          controller?._timer?.cancel();

          Future<void>? dispose = controller?._player?.dispose();
          controller?._player = null;
          await dispose;
        },
      );
      controller._stream_controller = stream_controller;
      _players[music] = controller;
    }

    return controller!;
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

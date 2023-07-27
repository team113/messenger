import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show MissingPluginException;

import 'audio_utils.dart';

/// Helper providing direct access to audio playback related resources.
class AudioUtilsImpl {
  /// [AudioPlayer] lazily initialized to play sounds [once].
  AudioPlayer? _player;

  /// [StreamController]s of [AudioSource]s added in [play].
  final Map<AudioSource, StreamController<void>> _players = {};

  /// Ensures the underlying resources are initialized to reduce possible delays
  /// when playing [once].
  void ensureInitialized() {
    if (_player == null) {
      // [AudioPlayer] constructor creates a hanging [Future], which can't be
      // awaited.
      runZonedGuarded(
        () => _player ??= AudioPlayer(),
        (e, _) {
          if (e is MissingPluginException) {
            _player = null;
          } else {
            throw e;
          }
        },
      );
    }
  }

  /// Plays the provided [sound] once.
  Future<void> once(AudioSource sound, {double? volume}) async {
    ensureInitialized();

    await runZonedGuarded(
      () async => await _player?.play(
        sound.source,
        position: Duration.zero,
        mode: PlayerMode.lowLatency,
        volume: volume,
      ),
      (e, _) {
        if (!e.toString().contains('NotAllowedError')) {
          throw e;
        }
      },
    );
  }

  /// Plays the provided [music] looped with the specified [fade].
  ///
  /// Stopping the [music] means canceling the returned [StreamSubscription].
  StreamSubscription<void> play(
    AudioSource music, {
    Duration fade = Duration.zero,
  }) {
    StreamController? controller = _players[music];

    if (controller == null) {
      AudioPlayer? player;
      Timer? timer;

      controller = StreamController.broadcast(
        onListen: () async {
          await runZonedGuarded(
            () async {
              player = AudioPlayer();
              await player?.play(music.source);
              await player?.setReleaseMode(ReleaseMode.loop);

              if (fade != Duration.zero) {
                timer = Timer.periodic(
                  Duration(microseconds: fade.inMicroseconds ~/ 10),
                  (timer) async {
                    if (timer.tick > 9) {
                      timer.cancel();
                    } else {
                      await player?.setVolume((timer.tick + 1) / 10);
                    }
                  },
                );
              }
            },
            (e, _) {
              if (e is! MissingPluginException ||
                  !e.toString().contains('NotAllowedError')) {
                throw e;
              }
            },
          );
        },
        onCancel: () async {
          _players.remove(music);
          timer?.cancel();
          await player?.dispose();
        },
      );

      _players[music] = controller;
    }

    return controller.stream.listen((_) {});
  }
}

/// Extension adding conversion from an [AudioSource] to a [Source].
extension on AudioSource {
  /// Returns a [Source]  corresponding to this [AudioSource].
  Source get source => switch (kind) {
        AudioSourceKind.asset => AssetSource((this as AssetAudioSource).asset),
        AudioSourceKind.file =>
          DeviceFileSource((this as FileAudioSource).file),
        AudioSourceKind.url => UrlSource((this as UrlAudioSource).url),
      };
}

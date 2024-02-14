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

import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mutex/mutex.dart';

import '/util/media_utils.dart';
import 'log.dart';
import 'platform_utils.dart';

/// Global variable to access [AudioUtilsImpl].
///
/// May be reassigned to mock specific functionally.
// ignore: non_constant_identifier_names
AudioUtilsImpl AudioUtils = AudioUtilsImpl();

/// Helper providing direct access to audio playback related resources.
class AudioUtilsImpl {
  /// [AudioPlayer] lazily initialized to play sounds [once].
  AudioPlayer? _player;

  /// [StreamController]s of [AudioSource]s added in [play].
  final Map<AudioSource, StreamController<void>> _players = {};

  /// [AudioSpeakerKind] currently used for audio output.
  AudioSpeakerKind? _speaker;

  /// [Mutex] guarding synchronized access to the [setSpeaker].
  final Mutex _mutex = Mutex();

  /// Ensures the underlying resources are initialized to reduce possible delays
  /// when playing [once].
  void ensureInitialized() {
    try {
      _player ??= AudioPlayer();
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

    await _player?.setAudioSource(sound);
    if (volume != null) {
      await _player?.setVolume(volume);
    }

    await _player?.play();
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
          try {
            player = AudioPlayer();
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

          await player?.setAudioSource(music);
          await player?.setLoopMode(LoopMode.all);
          await player?.play();

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

  /// Sets the [speaker] to use for audio output.
  Future<void> setSpeaker(AudioSpeakerKind speaker) async {
    _speaker = speaker;

    await _setSpeaker();
  }

  /// Sets the [speaker] to use for audio output.
  Future<void> _setSpeaker() async {
    if (_mutex.isLocked) {
      return;
    }

    await _mutex.protect(() async {
      await MediaUtils.outputGuard.protect(() async {
        final AudioSpeakerKind speaker = _speaker!;

        if (PlatformUtils.isIOS) {
          await AVAudioSession().setCategory(
            AVAudioSessionCategory.playAndRecord,
            AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.allowBluetoothA2dp |
                AVAudioSessionCategoryOptions.allowAirPlay,
            AVAudioSessionMode.voiceChat,
          );

          switch (speaker) {
            case AudioSpeakerKind.headphones:
              await AVAudioSession()
                  .overrideOutputAudioPort(AVAudioSessionPortOverride.none);
              break;

            case AudioSpeakerKind.earpiece:
              await AVAudioSession()
                  .overrideOutputAudioPort(AVAudioSessionPortOverride.none);
              break;

            case AudioSpeakerKind.speaker:
              await AVAudioSession()
                  .overrideOutputAudioPort(AVAudioSessionPortOverride.speaker);
              break;
          }
          return;
        }

        final session = await AudioSession.instance;

        await session.configure(
          const AudioSessionConfiguration(
            androidAudioAttributes: AndroidAudioAttributes(
              usage: AndroidAudioUsage.voiceCommunication,
              flags: AndroidAudioFlags.none,
              contentType: AndroidAudioContentType.speech,
            ),
          ),
        );

        switch (speaker) {
          case AudioSpeakerKind.headphones:
            await AndroidAudioManager()
                .setMode(AndroidAudioHardwareMode.inCommunication);
            await AndroidAudioManager().startBluetoothSco();
            await AndroidAudioManager().setBluetoothScoOn(true);
            break;

          case AudioSpeakerKind.speaker:
            await AndroidAudioManager().requestAudioFocus(
              const AndroidAudioFocusRequest(
                gainType: AndroidAudioFocusGainType.gain,
                audioAttributes: AndroidAudioAttributes(
                  contentType: AndroidAudioContentType.music,
                  usage: AndroidAudioUsage.media,
                ),
              ),
            );
            await AndroidAudioManager()
                .setMode(AndroidAudioHardwareMode.inCall);
            await AndroidAudioManager().stopBluetoothSco();
            await AndroidAudioManager().setBluetoothScoOn(false);
            await AndroidAudioManager().setSpeakerphoneOn(true);
            break;

          case AudioSpeakerKind.earpiece:
            await AndroidAudioManager()
                .setMode(AndroidAudioHardwareMode.inCommunication);
            await AndroidAudioManager().stopBluetoothSco();
            await AndroidAudioManager().setBluetoothScoOn(false);
            await AndroidAudioManager().setSpeakerphoneOn(false);
            break;
        }

        if (speaker != _speaker) {
          _setSpeaker();
        }
      });
    });
  }
}

/// Possible [AudioSource] kind.
enum AudioSourceKind { asset, file, url }

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
import 'package:just_audio/just_audio.dart' as ja;
import 'package:media_kit/media_kit.dart' as mk;
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
  /// [mk.Player] lazily initialized to play sounds [once].
  mk.Player? _player;

  /// [ja.AudioPlayer] lazily initialized to play sounds [once] on mobile
  /// platforms.
  ///
  /// [ja.AudioPlayer] is used on mobile platforms due to it accounting
  /// [AudioSession] preferences (e.g. switching audio output for mobiles),
  /// which [mk.Player] doesn't do.
  ja.AudioPlayer? _jaPlayer;

  /// [StreamController]s of [AudioSource]s added in [play].
  final Map<AudioSource, StreamController<void>> _players = {};

  /// [AudioSpeakerKind] currently used for audio output.
  AudioSpeakerKind? _speaker;

  /// [Mutex] guarding synchronized access to the [_setSpeaker].
  final Mutex _mutex = Mutex();

  /// Indicates whether the [_jaPlayer] should be used.
  bool get _isMobile => PlatformUtils.isMobile && !PlatformUtils.isWeb;

  /// Ensures the underlying resources are initialized to reduce possible delays
  /// when playing [once].
  void ensureInitialized() {
    try {
      if (_isMobile) {
        _jaPlayer ??= ja.AudioPlayer();
      } else {
        _player ??= mk.Player();
      }
    } catch (e) {
      // If [mk.Player] isn't available on the current platform, this throws a
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
  Future<void> once(AudioSource sound) async {
    ensureInitialized();

    if (_isMobile) {
      await _jaPlayer?.setAudioSource(sound.source);
      await _jaPlayer?.play();
    } else {
      await _player?.open(sound.media);
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
      ja.AudioPlayer? jaPlayer;
      mk.Player? player;
      Timer? timer;

      controller = StreamController.broadcast(
        onListen: () async {
          try {
            if (_isMobile) {
              jaPlayer = ja.AudioPlayer();
            } else {
              player = mk.Player();
            }
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

          if (_isMobile) {
            await jaPlayer?.setAudioSource(music.source);
            await jaPlayer?.setLoopMode(ja.LoopMode.all);
            await jaPlayer?.play();
          } else {
            await player?.open(music.media);

            // TODO: Wait for `media_kit` to improve [mk.PlaylistMode.loop] in Web.
            if (PlatformUtils.isWeb) {
              position = player?.stream.completed.listen((e) async {
                await player?.seek(Duration.zero);
                await player?.play();
              });
            } else {
              await player?.setPlaylistMode(mk.PlaylistMode.loop);
            }
          }

          if (fade != Duration.zero) {
            await (jaPlayer?.setVolume ?? player?.setVolume)?.call(0);

            timer = Timer.periodic(
              Duration(microseconds: fade.inMicroseconds ~/ 10),
              (timer) async {
                if (timer.tick > 9) {
                  timer.cancel();
                } else {
                  await jaPlayer?.setVolume((timer.tick + 1) / 10);
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

          Future<void>? dispose = jaPlayer?.dispose() ?? player?.dispose();
          jaPlayer = null;
          player = null;
          await dispose;
        },
      );

      _players[music] = controller;
    }

    return controller.stream.listen((_) {});
  }

  /// Sets the [speaker] to use for audio output.
  ///
  /// Only meaningful on mobile devices.
  Future<void> setSpeaker(AudioSpeakerKind speaker) async {
    if (_isMobile && _speaker != speaker) {
      _speaker = speaker;
      await _setSpeaker();
    }
  }

  /// Sets the default audio output device as the used one.
  ///
  /// Only meaningful on mobile devices.
  Future<void> setDefaultSpeaker() async {
    if (_isMobile) {
      final AudioSession session = await AudioSession.instance;
      final Set<AudioDevice> devices =
          await session.getDevices(includeInputs: false);
      final bool hasHeadphones = devices.any(
        (e) =>
            e.type == AudioDeviceType.wiredHeadset ||
            e.type == AudioDeviceType.wiredHeadphones ||
            e.type == AudioDeviceType.bluetoothA2dp ||
            e.type == AudioDeviceType.bluetoothLe ||
            e.type == AudioDeviceType.bluetoothSco ||
            e.type == AudioDeviceType.usbAudio,
      );

      if (hasHeadphones) {
        await setSpeaker(AudioSpeakerKind.headphones);
      } else {
        await setSpeaker(AudioSpeakerKind.speaker);
      }

      if (PlatformUtils.isAndroid) {
        await AndroidAudioManager().setMode(AndroidAudioHardwareMode.normal);
      } else if (PlatformUtils.isIOS) {
        await AVAudioSession().setCategory(
          AVAudioSessionCategory.playAndRecord,
          AVAudioSessionCategoryOptions.allowBluetooth,
          AVAudioSessionMode.defaultMode,
        );
      }
    }
  }

  /// Sets the [_speaker] to use for audio output.
  ///
  /// Should only be called via [setSpeaker].
  Future<void> _setSpeaker() async {
    // If the [_mutex] is locked, the output device is already being set.
    if (_mutex.isLocked) {
      return;
    }

    // [_speaker] is guaranteed to be non-`null` in [setSpeaker].
    final AudioSpeakerKind speaker = _speaker!;

    await _mutex.protect(() async {
      await MediaUtils.outputGuard.protect(() async {
        if (PlatformUtils.isIOS) {
          await AVAudioSession().setCategory(
            AVAudioSessionCategory.playAndRecord,
            AVAudioSessionCategoryOptions.allowBluetooth,
            AVAudioSessionMode.voiceChat,
          );

          switch (speaker) {
            case AudioSpeakerKind.headphones:
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
      });
    });

    // If the [_speaker] was changed while setting the output device then
    // call [_setSpeaker] again.
    if (speaker != _speaker) {
      _setSpeaker();
    }
  }
}

/// Common audio player interface to interact both
/// with [ja.AudioPlayer] and [mk.Player].
abstract class AudioPlayer {
  /// Sets the [AudioSource] to play.
  void setTrack(AudioSource song);

  /// Sets [AudioSource] and triggers play.
  void play(AudioSource song);

  /// Resumes currently loaded track.
  void resume();

  /// Triggers pause.
  void pause();

  /// Seeks to specified position of the [AudioSource].
  void seek(Duration position);

  /// Triggers stop.
  void stop();

  /// Disposes the player.
  void dispose();

  /// Stream indicating whether the player is currently playing.
  Stream<bool> get playingStream;

  /// Stream indicating whether the player is currently buffering.
  Stream<bool> get bufferingStream;

  /// Stream indicating whether the player has completed playing.
  Stream<bool> get completedStream;

  /// Stream providing the current playback position.
  Stream<Duration> get positionStream;

  /// Stream providing the total duration of the current track.
  Stream<Duration> get durationStream;

  /// Stream providing the buffered position of the current track.
  Stream<Duration> get bufferedPositionStream;
}

/// Adapter class for just_audio library that implements
/// the common [AudioPlayer] interface.
class JustAudioPlayerAdapter implements AudioPlayer {
  /// Initializes just_audio [ja.AudioPlayer] instance.
  final ja.AudioPlayer _player = ja.AudioPlayer();

  @override
  void setTrack(AudioSource song) async {
    _player.setAudioSource(song.source);
  }

  @override
  void play(AudioSource song) async {
    _player.setAudioSource(song.source);
    _player.play();
  }

  @override
  void resume() {
    _player.play();
  }

  @override
  void pause() {
    _player.pause();
  }

  @override
  void seek(Duration position) {
    _player.seek(position);
  }

  @override
  void stop() {
    _player.stop();
  }

  @override
  void dispose() {
    _player.dispose();
  }

  @override
  Stream<bool> get playingStream => _player.playingStream;

  @override
  Stream<bool> get bufferingStream => _player.processingStateStream
      .map((state) => state == ja.ProcessingState.buffering);

  @override
  Stream<bool> get completedStream => _player.processingStateStream
      .map((state) => state == ja.ProcessingState.completed);

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration> get durationStream => _player.durationStream
      .where((duration) => duration != null)
      .map((duration) => duration!);

  @override
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
}

/// Adapter class for media_kit library that implements
/// the common [AudioPlayer] interface.
class MediaKitPlayerAdapter implements AudioPlayer {
  /// Initializes media_kit [mk.Player] instance.
  final mk.Player _player = mk.Player();

  @override
  void setTrack(AudioSource song) async {
    await _player.open(
      song.media,
      play: false,
    );
  }

  @override
  void play(AudioSource song) async {
    _player.open(song.media);
  }

  @override
  void resume() async {
    _player.play();
  }

  @override
  void pause() {
    _player.pause();
  }

  @override
  void seek(Duration position) {
    _player.seek(position);
  }

  @override
  void stop() {
    _player.stop();
  }

  @override
  void dispose() {
    _player.dispose();
  }

  @override
  Stream<bool> get playingStream => _player.stream.playing;

  @override
  Stream<bool> get bufferingStream => _player.stream.buffering;

  @override
  Stream<bool> get completedStream => _player.stream.completed;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Stream<Duration> get bufferedPositionStream => _player.stream.buffer;
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

/// Extension adding conversion from an [AudioSource] to a [mk.Media] or
/// [ja.AudioSource].
extension on AudioSource {
  /// Returns a [Media] corresponding to this [AudioSource].
  mk.Media get media => switch (kind) {
        AudioSourceKind.asset => mk.Media(
            'asset:///assets/${PlatformUtils.isWeb ? 'assets/' : ''}${(this as AssetAudioSource).asset}',
          ),
        AudioSourceKind.file =>
          mk.Media('file:///${(this as FileAudioSource).file}'),
        AudioSourceKind.url => mk.Media((this as UrlAudioSource).url),
      };

  /// Returns a [ja.AudioSource] corresponding to this [AudioSource].
  ja.AudioSource get source => switch (kind) {
        AudioSourceKind.asset =>
          ja.AudioSource.asset('assets/${(this as AssetAudioSource).asset}'),
        AudioSourceKind.file =>
          ja.AudioSource.file((this as FileAudioSource).file),
        AudioSourceKind.url =>
          ja.AudioSource.uri(Uri.parse((this as UrlAudioSource).url)),
      };
}

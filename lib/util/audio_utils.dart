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
import 'package:collection/collection.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:medea_jason/medea_jason.dart';
import 'package:media_kit/media_kit.dart';
import 'package:messenger/util/media_utils.dart';

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
  final Map<AudioSource, AudioPlayback> _players = {};

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

  /// Plays the provided [music] looped with the specified [fade].
  ///
  /// Stopping the [music] means canceling the returned [AudioPlayback].
  AudioPlayback play(
    AudioSource music, {
    Duration fade = Duration.zero,
    AudioSpeakerKind speaker = AudioSpeakerKind.speaker,
    void Function()? onDone,
  }) {
    Log.debug('play($music)', '$runtimeType');

    AudioPlayback? playback = _players[music];
    StreamSubscription? position;

    if (playback == null) {
      playback = AudioPlayback();

      if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
        playback._controller = StreamController.broadcast(
          onListen: () async {
            Log.debug('play($music): onListen', '$runtimeType');

            playback?._jaPlayer = ja.AudioPlayer();

            if (onDone == null) {
              await playback?._jaPlayer?.setLoopMode(ja.LoopMode.all);
            }

            await playback?._jaPlayer?.setAudioSource(music.source);

            final AudioSession session = await AudioSession.instance;
            final bool hasBluetooth =
                (await session.getDevices(includeInputs: false)).any(
              (e) =>
                  e.type == AudioDeviceType.wiredHeadset ||
                  e.type == AudioDeviceType.wiredHeadphones ||
                  e.type == AudioDeviceType.bluetoothA2dp ||
                  e.type == AudioDeviceType.bluetoothLe ||
                  e.type == AudioDeviceType.bluetoothSco ||
                  e.type == AudioDeviceType.airPlay,
            );

            print(
                '!!!!!! hasBluetooth: $hasBluetooth, ${(await session.getDevices(includeInputs: false)).map((e) => e.name)}');

            await playback?.setSpeaker(
              // AudioSpeakerKind.speaker,
              hasBluetooth ? AudioSpeakerKind.headphones : speaker,
            );

            await playback?._jaPlayer?.play();

            onDone?.call();
          },
          onCancel: () async {
            Log.debug('play($music): onCancel', '$runtimeType');

            _players.remove(music);
            position?.cancel();

            Future<void>? dispose = playback?._jaPlayer?.dispose();
            playback?._jaPlayer = null;
            await dispose;
          },
        );
      } else {
        Timer? timer;

        playback._controller = StreamController.broadcast(
          onListen: () async {
            Log.debug('play($music): onListen', '$runtimeType');

            try {
              playback?._player = Player();
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

            Log.debug(
              'play($music): devices = ${_player?.state.audioDevices.map((e) => '${e.name}: ${e.description}')}',
              '$runtimeType',
            );

            Log.debug('play($music), speaker($speaker)', '$runtimeType');

            await playback?._player?.open(music.media);

            if (onDone != null) {
              bool first = true;

              position = playback?._player?.stream.completed.listen((e) async {
                if (first) {
                  first = false;
                } else {
                  onDone();
                }
              });
            } else {
              // TODO: Wait for `media_kit` to improve [PlaylistMode.loop] in Web.
              if (PlatformUtils.isWeb) {
                position =
                    playback?._player?.stream.completed.listen((e) async {
                  await playback?._player?.seek(Duration.zero);
                  await playback?._player?.play();
                });
              } else {
                await playback?._player?.setPlaylistMode(PlaylistMode.loop);
              }
            }

            if (fade != Duration.zero) {
              await playback?._player?.setVolume(0);
              timer = Timer.periodic(
                Duration(microseconds: fade.inMicroseconds ~/ 10),
                (timer) async {
                  if (timer.tick > 9) {
                    timer.cancel();
                  } else {
                    await playback?._player
                        ?.setVolume(100 * (timer.tick + 1) / 10);
                  }
                },
              );
            }

            Log.debug('play($music): onListen done', '$runtimeType');
          },
          onCancel: () async {
            Log.debug('play($music): onCancel', '$runtimeType');

            _players.remove(music);
            position?.cancel();
            timer?.cancel();

            Future<void>? dispose = playback?._player?.dispose();
            playback?._player = null;
            await dispose;
          },
        );
      }

      _players[music] = playback;
    }

    return _players[music]!..listen();
  }
}

enum AudioSpeakerKind { headphones, earpiece, speaker }

class AudioPlayback {
  AudioPlayback();

  Player? _player;
  ja.AudioPlayer? _jaPlayer;

  StreamController? _controller;
  StreamSubscription? _subscription;

  Future<void> setSpeaker(AudioSpeakerKind speaker) async {
    Log.debug('setSpeaker($speaker)', '$runtimeType');

    if (PlatformUtils.isIOS) {
      final devices = await MediaUtils.enumerateDevices();
      final device = devices.firstWhereOrNull((e) => e.speaker == speaker);
      if (device != null) {
        await MediaUtils.setOutputDevice(device.deviceId());
      }

      // if (speaker == AudioSpeakerKind.earpiece) {
      //   final session = await AudioSession.instance;
      //   await session.configure(
      //     const AudioSessionConfiguration(
      //       avAudioSessionMode: AVAudioSessionMode.voiceChat,
      //       avAudioSessionCategoryOptions:
      //           AVAudioSessionCategoryOptions.defaultToSpeaker,
      //       avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      //     ),
      //   );
      // }
      return;
    }

    final session = await AudioSession.instance;

    switch (speaker) {
      case AudioSpeakerKind.headphones:
        if (PlatformUtils.isAndroid) {
          await AndroidAudioManager().startBluetoothSco();
          await AndroidAudioManager().setBluetoothScoOn(true);
        }

        await session.configure(
          const AudioSessionConfiguration.music().copyWith(
            androidAudioAttributes: const AndroidAudioAttributes(
              contentType: AndroidAudioContentType.speech,
              usage: AndroidAudioUsage.voiceCommunication,
            ),
            androidAudioFocusGainType:
                AndroidAudioFocusGainType.gainTransientExclusive,
            avAudioSessionCategoryOptions:
                AVAudioSessionCategoryOptions.defaultToSpeaker |
                    AVAudioSessionCategoryOptions.allowBluetooth,
            avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          ),
        );
        break;

      case AudioSpeakerKind.speaker:
        if (PlatformUtils.isAndroid) {
          await AndroidAudioManager().stopBluetoothSco();
          await AndroidAudioManager().setBluetoothScoOn(false);
          await AndroidAudioManager().setSpeakerphoneOn(true);
        }

        await session.configure(
          const AudioSessionConfiguration.music().copyWith(
            androidAudioAttributes: const AndroidAudioAttributes(
              contentType: AndroidAudioContentType.music,
              flags: AndroidAudioFlags.none,
              usage: AndroidAudioUsage.notification,
            ),
            avAudioSessionCategoryOptions:
                AVAudioSessionCategoryOptions.defaultToSpeaker,
            avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          ),
        );
        break;

      case AudioSpeakerKind.earpiece:
        if (PlatformUtils.isAndroid) {
          await AndroidAudioManager()
              .setMode(AndroidAudioHardwareMode.inCommunication);
          await AndroidAudioManager().stopBluetoothSco();
          await AndroidAudioManager().setBluetoothScoOn(false);
          await AndroidAudioManager().setSpeakerphoneOn(false);
        }

        await session.configure(
          const AudioSessionConfiguration(
            androidAudioAttributes: AndroidAudioAttributes(
              usage: AndroidAudioUsage.voiceCommunication,
              flags: AndroidAudioFlags.none,
              contentType: AndroidAudioContentType.speech,
            ),
            avAudioSessionMode: AVAudioSessionMode.voiceChat,
            avAudioSessionCategoryOptions:
                AVAudioSessionCategoryOptions.defaultToSpeaker,
            avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          ),
        );
        break;
    }
  }

  void listen() {
    _subscription ??= _controller?.stream.listen((_) {});
  }

  void cancel() {
    _subscription?.cancel();
    _subscription = null;
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

  ja.AudioSource get source => switch (kind) {
        AudioSourceKind.asset =>
          ja.AudioSource.asset('assets/${(this as AssetAudioSource).asset}'),
        AudioSourceKind.file =>
          ja.AudioSource.file((this as FileAudioSource).file),
        AudioSourceKind.url =>
          ja.AudioSource.uri(Uri.parse((this as UrlAudioSource).url)),
      };
}

extension MediaDeviceToSpeakerExtension on MediaDeviceDetails {
  AudioSpeakerKind get speaker {
    if (deviceId() == 'ear-speaker' || deviceId() == 'ear-piece') {
      return AudioSpeakerKind.earpiece;
    } else if (deviceId() == 'speakerphone' || deviceId() == 'speaker') {
      return AudioSpeakerKind.speaker;
    } else {
      return AudioSpeakerKind.headphones;
    }
  }
}

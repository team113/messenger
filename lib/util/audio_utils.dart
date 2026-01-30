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

import 'package:audio_session/audio_session.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mutex/mutex.dart';
import 'package:uuid/uuid.dart';

import '/pubspec.g.dart';
import '/util/media_utils.dart';
import 'log.dart';
import 'new_type.dart';
import 'platform_utils.dart';
import 'web/web_utils.dart';

/// Global variable to access [AudioUtilsImpl].
///
/// May be reassigned to mock specific functionally.
// ignore: non_constant_identifier_names
AudioUtilsImpl AudioUtils = AudioUtilsImpl();

/// Helper providing direct access to audio playback related resources.
class AudioUtilsImpl {
  /// [AudioSpeakerKind] currently used for audio output.
  ///
  /// Only meaningful for mobile devices, since under desktop and Web the
  /// [MediaUtils] work much better with handling everything.
  final Rx<AudioSpeakerKind?> speaker = Rx(null);

  /// [DeviceDetails] of the currently used output device.
  final Rx<DeviceDetails?> outputDevice = Rx(null);

  /// [ja.AudioPlayer] lazily initialized to play sounds [once] on mobile
  /// platforms.
  ja.AudioPlayer? _jaPlayer;

  /// [StreamController]s of [AudioSource]s added in [play].
  final Map<AudioSource, StreamController<void>> _players = {};

  /// [Mutex] guarding synchronized access to the [_setSpeaker].
  final Mutex _mutex = Mutex();

  /// [Mutex] guarding synchronized output device updating.
  final Mutex _outputGuard = Mutex();

  /// [StreamController] to related [_intents] in [acquire].
  final Map<_IntentId, StreamController> _controllers = {};

  /// [_AudioIntent] applied via [acquire].
  final Map<_IntentId, _AudioIntent> _intents = {};

  /// [AudioSessionConfiguration] previously applied during [reconfigure].
  AudioSessionConfiguration? _previousConfiguration;

  /// Returns [Stream] of [AVAudioSessionRouteChange]s.
  Stream<AVAudioSessionRouteChange> get routeChangeStream =>
      AVAudioSession().routeChangeStream;

  /// Indicates whether the [_jaPlayer] should be used.
  bool get _isMobile => PlatformUtils.isMobile && !PlatformUtils.isWeb;

  /// Ensures the underlying resources are initialized to reduce possible delays
  /// when playing [once].
  void ensureInitialized() {
    try {
      // Set `handleAudioSessionActivation` to `false` to avoid stopping
      // background audio on [once].
      _jaPlayer ??= ja.AudioPlayer(handleAudioSessionActivation: false);
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
  Future<void> once(
    AudioSource sound, {
    AudioMode? mode = AudioMode.sound,
  }) async {
    Log.debug('once($sound)', '$runtimeType');

    ensureInitialized();

    StreamSubscription<void>? handle = switch (mode) {
      null => null,
      (_) => acquire(mode).listen((_) {}),
    };

    try {
      if (PlatformUtils.isWeb) {
        final String url = sound.direct;

        if (url.isNotEmpty) {
          await (WebUtils.play(
            '$url?${Pubspec.ref}',
          )).listen((_) {}).asFuture();
        }
      } else {
        await _jaPlayer?.setAudioSource(sound.source);
        await _jaPlayer?.play();
      }
    } finally {
      handle?.cancel();
    }
  }

  /// Plays the provided [music] looped with the specified [fade].
  ///
  /// Stopping the [music] means canceling the returned [StreamSubscription].
  StreamSubscription<void> play(
    AudioSource music, {
    Duration fade = Duration.zero,
    AudioMode mode = AudioMode.music,
  }) {
    Log.debug('play($music, mode: ${mode.name})', '$runtimeType');

    StreamController? controller = _players[music];
    StreamSubscription? playback;

    if (controller == null) {
      Stream<void>? handle = acquire(mode);
      StreamSubscription<void>? listening;

      ja.AudioPlayer? jaPlayer;
      Timer? timer;

      controller = StreamController.broadcast(
        onListen: () async {
          if (PlatformUtils.isWeb) {
            listening?.cancel();
            listening = handle.listen((_) {});

            playback?.cancel();
            playback = WebUtils.play(
              '${music.direct}?${Pubspec.ref}',
              loop: true,
            ).listen((_) {});

            return;
          }

          try {
            jaPlayer = ja.AudioPlayer();
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

          await jaPlayer?.setAudioSource(music.source);
          await jaPlayer?.setLoopMode(ja.LoopMode.all);

          listening?.cancel();
          listening = handle.listen((_) {});

          await jaPlayer?.play();

          if (fade != Duration.zero) {
            await jaPlayer?.setVolume(0);

            timer = Timer.periodic(
              Duration(microseconds: fade.inMicroseconds ~/ 10),
              (timer) async {
                if (timer.tick > 9) {
                  timer.cancel();
                } else {
                  await jaPlayer?.setVolume((timer.tick + 1) / 10);
                }
              },
            );
          }
        },
        onCancel: () async {
          listening?.cancel();

          if (PlatformUtils.isWeb) {
            playback?.cancel();
            return;
          }

          _players.remove(music);
          timer?.cancel();

          Future<void>? dispose = jaPlayer?.dispose();
          jaPlayer = null;
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
  Future<void> setSpeaker(
    AudioSpeakerKind speaker, {
    bool force = false,
  }) async {
    Log.debug('setSpeaker(${speaker.name}, force: $force)', '$runtimeType');

    if (_isMobile && (this.speaker.value != speaker || force)) {
      this.speaker.value = speaker;

      try {
        await _setSpeaker();
      } catch (e) {
        Log.warning(
          'Unable to `_setSpeaker(${speaker.name})` due to $e',
          '$runtimeType',
        );
      }
    }
  }

  /// Sets device with [device] as a currently used output device.
  Future<void> setOutputDevice(DeviceDetails device) async {
    Log.debug(
      'setOutputDevice(${device.id()}, ${device.label()}, ${device.speaker.name})',
      '$runtimeType',
    );

    // On mobile platforms there's no need to do `medea_jason` or `MediaUtils`
    // way of changing the output, since we're doing the same in `_setSpeaker()`
    // method, which does `AVAudioSession` and `AndroidAudioManager` stuff.
    if (_isMobile) {
      if (_isMobile && speaker.value != device.speaker) {
        speaker.value = device.speaker;
        await _setSpeaker();
      }

      return;
    }

    if (outputDevice.value?.deviceId() != device.deviceId()) {
      outputDevice.value = device;
      await _setOutputDevice();
    }
  }

  /// Sets the default audio output device as the used one.
  ///
  /// Only meaningful on mobile devices.
  Future<void> setDefaultSpeaker() async {
    Log.debug('setDefaultSpeaker()', '$runtimeType');

    if (_isMobile) {
      final AudioSession session = await AudioSession.instance;
      final Set<AudioDevice> devices = await session.getDevices(
        includeInputs: false,
      );
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
    }
  }

  /// Acquires and returns the handle for the provided [AudioMode].
  ///
  /// The returned [Stream] must be listened to when [mode] is still needed, and
  /// released when the [mode] is no longer needed.
  ///
  /// [speaker] can be set to transition the currently selected one into that
  /// when intent is acquire for the first time.
  Stream<void> acquire(AudioMode mode, {AudioSpeakerKind? speaker}) {
    final _AudioIntent intent = _AudioIntent(mode, speaker: speaker);

    final StreamController<void> controller = StreamController.broadcast(
      onListen: () async {
        Log.debug(
          'acquire($mode) -> onListen for ${intent.id} with `${speaker?.name}`',
          '$runtimeType',
        );

        _intents[intent.id] = intent;
        await reconfigure(preferredSpeaker: speaker);
      },
      onCancel: () async {
        Log.debug(
          'acquire($mode) -> onCancel for ${intent.id}',
          '$runtimeType',
        );

        _intents.remove(intent.id);
        await reconfigure();
      },
    );

    _controllers[intent.id] = controller;

    return controller.stream;
  }

  /// Configures the current [AudioSession] to reflect the [AudioMode]s applied.
  Future<void> reconfigure({
    bool force = false,
    AudioSpeakerKind? preferredSpeaker,
  }) async {
    Log.debug(
      'reconfigure($force, $preferredSpeaker) -> intents are [${_intents.values.map((e) => e.mode.name).join(', ')}]',
      '$runtimeType',
    );

    if (_intents.isEmpty) {
      if (!PlatformUtils.isWeb) {
        // Reset back to speaker, but only if headphones are disconnected.
        if (speaker.value != AudioSpeakerKind.headphones) {
          await setSpeaker(AudioSpeakerKind.speaker);
        }

        if (PlatformUtils.isIOS) {
          await AVAudioSession().setActive(false);
        }
      }
    } else {
      final bool needsMic = _intents.values.any((e) => e.mode.needsMic);

      final AudioSessionConfiguration configuration = AudioSessionConfiguration(
        avAudioSessionCategory: needsMic
            ? AVAudioSessionCategory.playAndRecord
            : AVAudioSessionCategory.playback,
        avAudioSessionMode: needsMic
            ? AVAudioSessionMode.voiceChat
            : AVAudioSessionMode.defaultMode,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers |
            AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.allowBluetoothA2dp,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: needsMic
              ? AndroidAudioContentType.speech
              : AndroidAudioContentType.music,
          usage: needsMic
              ? AndroidAudioUsage.voiceCommunication
              : AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
      );

      if (configuration.toJson() == _previousConfiguration?.toJson()) {
        Log.debug(
          'reconfigure() -> ignoring ${_intents.values.map((e) => e.mode.name).join(', ')}',
          '$runtimeType',
        );

        return;
      }

      _previousConfiguration = configuration;

      final AudioSession session = await AudioSession.instance;

      try {
        await session.configure(configuration);
        await session.setActive(true, fallbackConfiguration: configuration);
      } catch (e) {
        Log.warning(
          'Failed to `session.configure()` due to: $e',
          '$runtimeType',
        );
      }

      if (preferredSpeaker != null) {
        // If we're using headphones, and the preferred one is speaker, then
        // shouldn't switch.
        if (speaker.value == AudioSpeakerKind.headphones &&
            preferredSpeaker == AudioSpeakerKind.speaker) {
          // No-op.
        } else {
          await setSpeaker(preferredSpeaker);
        }
      } else if (_isMobile) {
        if (speaker.value != null) {
          await setSpeaker(speaker.value!, force: force);
        }
      }
    }
  }

  /// Sets the [speaker] to use for audio output.
  ///
  /// Should only be called via [setSpeaker].
  Future<void> _setSpeaker() async {
    Log.debug('_setSpeaker(${this.speaker.value?.name})', '$runtimeType');

    // [_speaker] is guaranteed to be non-`null` in [setSpeaker].
    final AudioSpeakerKind speaker = this.speaker.value!;

    await _mutex.protect(() async {
      await _outputGuard.protect(() async {
        if (PlatformUtils.isIOS) {
          switch (speaker) {
            case AudioSpeakerKind.headphones:
            case AudioSpeakerKind.earpiece:
              Log.debug(
                '_setSpeaker(${this.speaker.value?.name}) -> await AVAudioSession().overrideOutputAudioPort(none)...',
                '$runtimeType',
              );

              await AVAudioSession().overrideOutputAudioPort(
                AVAudioSessionPortOverride.none,
              );

              Log.debug(
                '_setSpeaker(${this.speaker.value?.name}) -> await AVAudioSession().overrideOutputAudioPort(none)... done!',
                '$runtimeType',
              );
              break;

            case AudioSpeakerKind.speaker:
              Log.debug(
                '_setSpeaker(${this.speaker.value?.name}) -> await AVAudioSession().overrideOutputAudioPort(speaker)...',
                '$runtimeType',
              );

              await AVAudioSession().overrideOutputAudioPort(
                AVAudioSessionPortOverride.speaker,
              );

              Log.debug(
                '_setSpeaker(${this.speaker.value?.name}) -> await AVAudioSession().overrideOutputAudioPort(speaker)... done!',
                '$runtimeType',
              );
              break;
          }

          return;
        }

        switch (speaker) {
          case AudioSpeakerKind.headphones:
            await AndroidAudioManager().startBluetoothSco();
            await AndroidAudioManager().setBluetoothScoOn(true);
            break;

          case AudioSpeakerKind.speaker:
            await AndroidAudioManager().stopBluetoothSco();
            await AndroidAudioManager().setBluetoothScoOn(false);
            await AndroidAudioManager().setSpeakerphoneOn(true);
            break;

          case AudioSpeakerKind.earpiece:
            await AndroidAudioManager().stopBluetoothSco();
            await AndroidAudioManager().setBluetoothScoOn(false);
            await AndroidAudioManager().setSpeakerphoneOn(false);
            break;
        }
      });
    });
  }

  /// Invokes a [MediaUtilsImpl.setOutputDevice] method.
  Future<void> _setOutputDevice() async {
    // If the [_mutex] is locked, the output device is already being set.
    if (_mutex.isLocked) {
      return;
    }

    final String? deviceId = outputDevice.value?.deviceId();
    if (deviceId == null) {
      return;
    }

    await _outputGuard.protect(() async {
      await _mutex.protect(() async {
        await MediaUtils.setOutputDevice(deviceId);
      });
    });

    // If the [outputDeviceId] was changed while setting the output device
    // then call [_setOutputDevice] again.
    if (deviceId != outputDevice.value?.deviceId()) {
      _setOutputDevice();
    }
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

/// Mode, in which [AudioUtils] should currently operate in.
enum AudioMode {
  sound,
  call,
  music,
  ringtone,
  video;

  bool get needsMic => switch (this) {
    AudioMode.sound ||
    AudioMode.music ||
    AudioMode.ringtone ||
    AudioMode.video => false,
    AudioMode.call => true,
  };
}

/// Intent for the [AudioUtils] to operate in the provided [AudioMode].
class _AudioIntent {
  _AudioIntent(this.mode, {this.speaker});

  /// [_IntentId] of this [_AudioIntent].
  final _IntentId id = _IntentId.generate();

  /// [AudioMode] itself.
  final AudioMode mode;

  /// [AudioSpeakerKind] to prefer when this [_AudioIntent] is active.
  final AudioSpeakerKind? speaker;
}

/// Unique ID of an [_AudioIntent].
class _IntentId extends NewType<String> {
  const _IntentId(super.val);

  /// Constructs a random [_IntentId].
  _IntentId.generate() : super(const Uuid().v4());
}

/// Extension adding conversion from an [AudioSource] to a [Media] or
/// [ja.AudioSource].
extension on AudioSource {
  /// Returns a [ja.AudioSource] corresponding to this [AudioSource].
  ja.AudioSource get source => switch (kind) {
    AudioSourceKind.asset => ja.AudioSource.asset(
      'assets/${(this as AssetAudioSource).asset}${PlatformUtils.isWeb ? '?${Pubspec.ref}' : ''}',
    ),
    AudioSourceKind.file => ja.AudioSource.file((this as FileAudioSource).file),
    AudioSourceKind.url => ja.AudioSource.uri(
      Uri.parse((this as UrlAudioSource).url),
    ),
  };

  /// Returns an actual URL corresponding to this [AudioSource].
  String get direct => switch (kind) {
    AudioSourceKind.asset => (this as AssetAudioSource).asset,
    AudioSourceKind.file => (this as FileAudioSource).file,
    AudioSourceKind.url => (this as UrlAudioSource).url,
  };
}

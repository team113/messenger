// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:medea_jason/medea_jason.dart';
import 'package:mutex/mutex.dart';

import '/l10n/l10n.dart';
import 'log.dart';
import 'platform_utils.dart';
import 'web/web_utils.dart';

/// Global variable to access [MediaUtilsImpl].
///
/// May be reassigned to mock specific functionally.
// ignore: non_constant_identifier_names
MediaUtilsImpl MediaUtils = MediaUtilsImpl();

/// Helper providing direct access to media related resources like media
/// devices, media tracks, etc.
class MediaUtilsImpl {
  /// ID of the currently used output device.
  final RxnString outputDeviceId = RxnString();

  /// [Mutex] guarding synchronized output device updating.
  final Mutex outputGuard = Mutex();

  /// [Jason] communicating with the media resources.
  Jason? _jason;

  /// [MediaManagerHandle] maintaining the media devices.
  MediaManagerHandle? __mediaManager;

  /// [StreamController] piping the [DeviceDetails] changes in the
  /// [MediaManagerHandle.onDeviceChange] callback.
  StreamController<List<DeviceDetails>>? _devicesController;

  /// [StreamController] piping the [MediaDisplayDetails] changes.
  StreamController<List<MediaDisplayDetails>>? _displaysController;

  /// [Mutex] guarding synchronized access to the [_setOutputDevice].
  final Mutex _mutex = Mutex();

  /// [Mutex] guarding asynchronous [jason] and [_mediaManager] initialization.
  final Mutex _guard = Mutex();

  /// Returns the [Jason] instance of these [MediaUtils].
  FutureOr<Jason?> get jason {
    if (_jason == null) {
      return _guard.protect(() async {
        if (_jason != null) {
          return _jason;
        }

        try {
          _jason = await Jason.init();
        } catch (e) {
          Log.debug(
            'Unable to invoke `Jason.init()` due to: $e',
            '$runtimeType',
          );

          // TODO: So the test would run. Jason currently only supports Web and
          //       Android, and unit tests run on a host machine.
          _jason = null;
        }

        WebUtils.onPanic((e) {
          Log.error('Panic: ${e.toString()}', 'Jason');
          _jason = null;
          __mediaManager = null;
        });

        return _jason;
      });
    }

    return _jason;
  }

  /// Returns the [MediaManagerHandle] instance of these [MediaUtils].
  FutureOr<MediaManagerHandle?> get _mediaManager {
    if (__mediaManager == null) {
      if (__mediaManager != null) {
        return __mediaManager;
      }

      final FutureOr<Jason?> instance = jason;
      if (instance is Future) {
        return _guard.protect(() async {
          return __mediaManager = (await instance)?.mediaManager();
        });
      }

      return __mediaManager = instance?.mediaManager();
    }

    return __mediaManager;
  }

  /// Returns a [Stream] of the [DeviceDetails] changes.
  Stream<List<DeviceDetails>> get onDeviceChange {
    if (_devicesController == null) {
      _devicesController = StreamController.broadcast();

      Future(() async {
        (await _mediaManager)?.onDeviceChange(() async {
          _devicesController?.add(
            (await enumerateDevices())
                .where((e) => e.deviceId().isNotEmpty)
                .toList(),
          );
        });
      });
    }

    return _devicesController!.stream;
  }

  /// Returns a [Stream] of the [MediaDisplayDetails] changes.
  Stream<List<MediaDisplayDetails>> get onDisplayChange {
    if (_displaysController == null) {
      _displaysController = StreamController.broadcast();

      if (PlatformUtils.isDesktop && !PlatformUtils.isWeb) {
        Future(() async {
          _displaysController?.add(
            (await (await _mediaManager)?.enumerateDisplays() ?? [])
                .where((e) => e.deviceId().isNotEmpty)
                .toList(),
          );
        });
      }
    }

    return _displaysController!.stream;
  }

  /// Returns [LocalMediaTrack]s of the [audio], [video] and [screen] devices.
  Future<List<LocalMediaTrack>> getTracks({
    AudioPreferences? audio,
    VideoPreferences? video,
    ScreenPreferences? screen,
  }) async {
    if (_mediaManager == null) {
      return [];
    }

    final List<LocalMediaTrack> tracks = [];

    if (audio != null || video != null || screen != null) {
      final List<LocalMediaTrack>? local = await (await _mediaManager)
          ?.initLocalTracks(
            _mediaStreamSettings(audio: audio, video: video, screen: screen),
          );

      if (local != null) {
        tracks.addAll(local);
      }
    }

    return tracks;
  }

  /// Returns the [DeviceDetails] currently available with the provided
  /// [kind], if specified.
  Future<List<DeviceDetails>> enumerateDevices([MediaDeviceKind? kind]) async {
    final List<DeviceDetails> devices =
        (await (await _mediaManager)?.enumerateDevices() ?? [])
            .where((e) => e.deviceId().isNotEmpty)
            .where((e) => kind == null || e.kind() == kind)
            .whereType<MediaDeviceDetails>()
            .map((e) => DeviceDetails(e))
            .toList();

    // Add the [DefaultMediaDeviceDetails] to the retrieved list of devices.
    //
    // Browsers and mobiles already may include their own default devices.
    if (kind == null || kind == MediaDeviceKind.audioInput) {
      final DeviceDetails? hasDefault = devices.firstWhereOrNull(
        (d) =>
            d.kind() == MediaDeviceKind.audioInput && d.deviceId() == 'default',
      );

      if (hasDefault == null) {
        final DeviceDetails? device = devices.firstWhereOrNull(
          (e) => e.kind() == MediaDeviceKind.audioInput,
        );
        if (device != null) {
          devices.insert(0, DefaultDeviceDetails(device));
        }
      } else {
        // Audio input on mobile devices is handled by `medea_jason`, and we
        // should not interfere, as otherwise we may run into
        // [MediaSettingsUpdateException].
        if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
          devices.remove(hasDefault);
        }
      }
    }

    if (kind == null || kind == MediaDeviceKind.audioOutput) {
      final bool hasDefault = devices.any(
        (d) =>
            d.kind() == MediaDeviceKind.audioOutput &&
            d.deviceId() == 'default',
      );

      if (!hasDefault) {
        final DeviceDetails? device = devices.firstWhereOrNull(
          (e) => e.kind() == MediaDeviceKind.audioOutput,
        );
        if (device != null) {
          devices.insert(0, DefaultDeviceDetails(device));
        }
      }
    }

    return devices;
  }

  /// Sets device with [deviceId] as a currently used output device.
  Future<void> setOutputDevice(String deviceId) async {
    if (outputDeviceId.value != deviceId) {
      outputDeviceId.value = deviceId;
      await _setOutputDevice();
    }
  }

  /// Invokes a [MediaManagerHandle.setOutputAudioId] method.
  Future<void> _setOutputDevice() async {
    // If the [_mutex] is locked, the output device is already being set.
    if (_mutex.isLocked) {
      return;
    }

    final String deviceId = outputDeviceId.value!;
    await outputGuard.protect(() async {
      await _mutex.protect(() async {
        if (PlatformUtils.isIOS && !PlatformUtils.isWeb) {
          await AVAudioSession().setCategory(
            AVAudioSessionCategory.playAndRecord,
            AVAudioSessionCategoryOptions.allowBluetooth,
            AVAudioSessionMode.voiceChat,
          );
        }

        await (await _mediaManager)?.setOutputAudioId(deviceId);
      });
    });

    // If the [outputDeviceId] was changed while setting the output device
    // then call [_setOutputDevice] again.
    if (deviceId != outputDeviceId.value) {
      _setOutputDevice();
    }
  }

  /// Returns the currently available [MediaDisplayDetails].
  Future<List<MediaDisplayDetails>> enumerateDisplays() async {
    if (!PlatformUtils.isDesktop || PlatformUtils.isWeb) {
      return [];
    }

    return (await (await _mediaManager)?.enumerateDisplays() ?? [])
        .where((e) => e.deviceId().isNotEmpty)
        .toList();
  }

  /// Ensures foreground service is running to support receiving microphone
  /// input when application is in background.
  ///
  /// Does nothing on non-Android operating systems.
  Future<void> ensureForegroundService() async {
    Log.debug('ensureForegroundService()', '$runtimeType');

    // TODO: Google Play doesn't allow applications to have foreground services
    //       without declarations that require video URLs demonstrating
    //       __working__ foreground service features usage.
    // await WebUtils.setupForegroundService();
  }

  /// Returns [MediaStreamSettings] with [audio], [video], [screen] enabled or
  /// not.
  MediaStreamSettings _mediaStreamSettings({
    AudioPreferences? audio,
    VideoPreferences? video,
    ScreenPreferences? screen,
  }) {
    final MediaStreamSettings settings = MediaStreamSettings();

    if (audio != null) {
      final AudioTrackConstraints constraints = AudioTrackConstraints();
      if (audio.device != null) constraints.deviceId(audio.device!);

      if (audio.noiseSuppression != null) {
        constraints.idealNoiseSuppression(audio.noiseSuppression!);
      }

      if ((audio.noiseSuppression ?? true) &&
          audio.noiseSuppressionLevel != null) {
        constraints.noiseSuppressionLevel(audio.noiseSuppressionLevel!);
      }

      if (audio.echoCancellation != null) {
        constraints.idealEchoCancellation(audio.echoCancellation!);
      }

      if (audio.autoGainControl != null) {
        constraints.idealAutoGainControl(audio.autoGainControl!);
      }

      if (audio.highPassFilter != null) {
        constraints.idealHighPassFilter(audio.highPassFilter!);
      }

      settings.audio(constraints);
    }

    if (video != null) {
      final DeviceVideoTrackConstraints constraints =
          DeviceVideoTrackConstraints();
      if (video.facingMode != null) {
        constraints.idealFacingMode(video.facingMode!);
      } else if (video.device != null) {
        constraints.deviceId(video.device!);
      }
      settings.deviceVideo(constraints);
    }

    if (screen != null) {
      final DisplayVideoTrackConstraints constraints =
          DisplayVideoTrackConstraints();
      if (screen.device != null) constraints.deviceId(screen.device!);
      constraints.idealFrameRate(screen.framerate ?? 30);
      settings.displayVideo(constraints);
    }

    return settings;
  }
}

/// [LocalMediaTrack] preferences.
class TrackPreferences {
  const TrackPreferences({this.device});

  /// ID of a device to use.
  final String? device;
}

/// [TrackPreferences] of a microphone track.
class AudioPreferences extends TrackPreferences {
  const AudioPreferences({
    super.device,
    this.noiseSuppression,
    this.noiseSuppressionLevel,
    this.echoCancellation,
    this.autoGainControl,
    this.highPassFilter,
  });

  /// Indicator whether noise suppression should be enabled.
  final bool? noiseSuppression;

  /// Desired noise suppression level, if enabled.
  final NoiseSuppressionLevel? noiseSuppressionLevel;

  /// Indicator whether echo cancellation should be enabled.
  final bool? echoCancellation;

  /// Indicator whether auto gain control should be enabled.
  final bool? autoGainControl;

  /// Indicator whether high pass filter should be enabled.
  final bool? highPassFilter;
}

/// [TrackPreferences] of a video camera track.
class VideoPreferences extends TrackPreferences {
  const VideoPreferences({super.device, this.facingMode});

  /// Preferred [FacingMode] of the video track.
  final FacingMode? facingMode;
}

/// [TrackPreferences] of a screen share track.
class ScreenPreferences extends TrackPreferences {
  const ScreenPreferences({super.device, this.framerate});

  /// Preferred framerate of the screen track.
  final int? framerate;
}

/// Extension adding conversion on [MediaDeviceDetails] to [AudioSpeakerKind].
extension MediaDeviceToSpeakerExtension on MediaDeviceDetails {
  /// Returns the [AudioSpeakerKind] of these [MediaDeviceDetails].
  ///
  /// Only meaningful, if these [MediaDeviceDetails] are of
  /// [MediaDeviceKind.audioOutput].
  AudioSpeakerKind get speaker => switch (deviceId()) {
    'ear-speaker' || 'ear-piece' => AudioSpeakerKind.earpiece,
    'speakerphone' || 'speaker' => AudioSpeakerKind.speaker,
    (_) => AudioSpeakerKind.headphones,
  };
}

/// Possible kind of an audio output device.
enum AudioSpeakerKind { headphones, earpiece, speaker }

/// Wrapper around a [MediaDeviceDetails] with [id] method.
///
/// [id] may be overridden to represent a different device.
class DeviceDetails extends MediaDeviceDetails {
  DeviceDetails(this._device);

  /// [MediaDeviceDetails] actually used by these [DeviceDetails].
  final MediaDeviceDetails _device;

  @override
  String deviceId() => _device.deviceId();

  @override
  void free() => _device.free();

  @override
  String? groupId() => _device.groupId();

  @override
  bool isFailed() => _device.isFailed();

  @override
  MediaDeviceKind kind() => _device.kind();

  @override
  String label() {
    final String description = _device.label();

    // Firefox in its private mode, for example, leaves the labels empty.
    if (description.isEmpty) {
      return deviceId();
    }

    return description;
  }

  @override
  String toString() => id();

  @override
  int get hashCode => (id() + deviceId()).hashCode;

  @override
  bool operator ==(Object other) {
    return other is DeviceDetails &&
        id() == other.id() &&
        deviceId() == other.deviceId() &&
        label() == other.label() &&
        // On Web `default` devices aren't equal.
        (!PlatformUtils.isWeb || deviceId() != 'default');
  }

  /// Returns a unique identifier of this [DeviceDetails].
  String id() => _device.deviceId();
}

/// [DeviceDetails] representing a default device.
class DefaultDeviceDetails extends DeviceDetails {
  DefaultDeviceDetails(super._device);

  @override
  void free() {
    // No-op.
  }

  @override
  String label() =>
      'label_device_by_default'.l10nfmt({'device': _device.label()});

  @override
  String id() => 'default';
}

/// Audio processing noise suppression aggressiveness.
enum NoiseSuppressionLevelWithOff {
  /// Disabled.
  off,

  /// Minimal noise suppression.
  low,

  /// Moderate level of suppression.
  moderate,

  /// Aggressive noise suppression.
  high,

  /// Maximum suppression.
  veryHigh;

  /// Converts this [NoiseSuppressionLevelWithOff] to actual
  /// [NoiseSuppressionLevel].
  NoiseSuppressionLevel toLevel() {
    return switch (this) {
      off || low => NoiseSuppressionLevel.low,
      moderate => NoiseSuppressionLevel.moderate,
      high => NoiseSuppressionLevel.high,
      veryHigh => NoiseSuppressionLevel.veryHigh,
    };
  }
}

/// Extention adding conversion of [NoiseSuppressionLevel] to
/// [NoiseSuppressionLevelWithOff].
extension NoiseSuppressionLevelToOff on NoiseSuppressionLevel {
  /// Converts this [NoiseSuppressionLevelWithOff] to actual
  /// [NoiseSuppressionLevel].
  NoiseSuppressionLevelWithOff toLevelWithOff([bool enabled = true]) {
    return switch (enabled) {
      false => NoiseSuppressionLevelWithOff.off,
      true => switch (this) {
        NoiseSuppressionLevel.low => NoiseSuppressionLevelWithOff.low,
        NoiseSuppressionLevel.moderate => NoiseSuppressionLevelWithOff.moderate,
        NoiseSuppressionLevel.high => NoiseSuppressionLevelWithOff.high,
        NoiseSuppressionLevel.veryHigh => NoiseSuppressionLevelWithOff.veryHigh,
      },
    };
  }
}

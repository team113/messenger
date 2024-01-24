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

import 'package:collection/collection.dart';
import 'package:medea_jason/medea_jason.dart';

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
  /// [Jason] communicating with the media resources.
  Jason? _jason;

  /// [MediaManagerHandle] maintaining the media devices.
  MediaManagerHandle? _mediaManager;

  /// [StreamController] piping the [MediaDeviceDetails] changes in the
  /// [MediaManagerHandle.onDeviceChange] callback.
  StreamController<List<MediaDeviceDetails>>? _devicesController;

  /// [StreamController] piping the [MediaDisplayDetails] changes.
  StreamController<List<MediaDisplayDetails>>? _displaysController;

  /// Returns the [Jason] instance of these [MediaUtils].
  Jason? get jason {
    if (_jason == null) {
      try {
        _jason = Jason();
      } catch (_) {
        // TODO: So the test would run. Jason currently only supports Web and
        //       Android, and unit tests run on a host machine.
        _jason = null;
      }

      WebUtils.onPanic((e) {
        Log.error('Panic: ${e.toString()}', 'Jason');
        _jason = null;
        _mediaManager = null;
      });
    }

    return _jason;
  }

  /// Returns the [MediaManagerHandle] instance of these [MediaUtils].
  MediaManagerHandle? get mediaManager {
    _mediaManager ??= jason?.mediaManager();
    return _mediaManager;
  }

  /// Returns a [Stream] of the [MediaDeviceDetails] changes.
  Stream<List<MediaDeviceDetails>> get onDeviceChange {
    if (_devicesController == null) {
      _devicesController = StreamController.broadcast();
      mediaManager?.onDeviceChange(() async {
        _devicesController?.add(
          (await enumerateDevices())
              .where((e) => e.deviceId().isNotEmpty)
              .toList(),
        );
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
            (await mediaManager?.enumerateDisplays() ?? [])
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
    if (mediaManager == null) {
      return [];
    }

    final List<LocalMediaTrack> tracks = [];

    if (audio != null || video != null || screen != null) {
      final List<LocalMediaTrack> local = await mediaManager!.initLocalTracks(
        _mediaStreamSettings(audio: audio, video: video, screen: screen),
      );

      tracks.addAll(local);
    }

    return tracks;
  }

  /// Returns the [MediaDeviceDetails] currently available with the provided
  /// [kind], if specified.
  Future<List<MediaDeviceDetails>> enumerateDevices([
    MediaDeviceKind? kind,
  ]) async {
    final List<MediaDeviceDetails> devices =
        (await mediaManager?.enumerateDevices() ?? [])
            .where((e) => e.deviceId().isNotEmpty)
            .where((e) => kind == null || e.kind() == kind)
            .whereType<MediaDeviceDetails>()
            .toList();

    if (!PlatformUtils.isWeb) {
      if (kind == null || kind == MediaDeviceKind.audioInput) {
        final MediaDeviceDetails? device = devices
            .firstWhereOrNull((e) => e.kind() == MediaDeviceKind.audioInput);
        if (device != null) {
          devices.insert(0, DefaultMediaDeviceDetails(device));
        }
      }

      if (kind == null || kind == MediaDeviceKind.audioOutput) {
        final MediaDeviceDetails? device = devices
            .firstWhereOrNull((e) => e.kind() == MediaDeviceKind.audioOutput);
        if (device != null) {
          devices.insert(0, DefaultMediaDeviceDetails(device));
        }
      }
    }

    return devices;
  }

  /// Returns the currently available [MediaDisplayDetails].
  Future<List<MediaDisplayDetails>> enumerateDisplays() async {
    if (!PlatformUtils.isDesktop || PlatformUtils.isWeb) {
      return [];
    }

    return (await mediaManager?.enumerateDisplays() ?? [])
        .where((e) => e.deviceId().isNotEmpty)
        .toList();
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
      settings.audio(constraints);
    }

    if (video != null) {
      final DeviceVideoTrackConstraints constraints =
          DeviceVideoTrackConstraints();
      if (video.device != null) constraints.deviceId(video.device!);
      if (video.facingMode != null) {
        constraints.idealFacingMode(video.facingMode!);
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
  const AudioPreferences({super.device});
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

/// [MediaDeviceDetails] representing the default device.
class DefaultMediaDeviceDetails extends MediaDeviceDetails {
  DefaultMediaDeviceDetails(this._deviceDetails);

  /// [MediaDeviceDetails] this [DefaultMediaDeviceDetails] represents.
  final MediaDeviceDetails _deviceDetails;

  @override
  String deviceId() => 'default';

  @override
  void free() => _deviceDetails.free();

  @override
  String? groupId() => _deviceDetails.groupId();

  @override
  bool isFailed() => _deviceDetails.isFailed();

  @override
  MediaDeviceKind kind() => _deviceDetails.kind();

  @override
  String label() => 'label_by_default_hyphen'.l10n + _deviceDetails.label();
}

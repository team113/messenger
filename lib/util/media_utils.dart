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

import 'package:medea_jason/medea_jason.dart';

import 'log.dart';
import 'platform_utils.dart';
import 'web/web_utils.dart';

/// Helper providing direct access to media related resources like media
/// devices, media tracks, etc.
class MediaUtils {
  /// [Jason] communicating with the media resources.
  static Jason? _jason;

  /// [MediaManagerHandle] maintaining the media devices.
  static MediaManagerHandle? _mediaManager;

  /// [StreamController] piping the [MediaDeviceDetails] changes in the
  /// [MediaManagerHandle.onDeviceChange] callback.
  static StreamController<List<MediaDeviceDetails>>? _devicesController;

  /// [StreamController] piping the [MediaDisplayDetails] changes.
  static StreamController<List<MediaDisplayDetails>>? _displaysController;

  /// Returns the [Jason] instance of these [MediaUtils].
  static Jason? get jason {
    if (_jason == null) {
      try {
        _jason = Jason();
      } catch (_) {
        // TODO: So the test would run. Jason currently only supports Web and
        //       Android, and unit tests run on a host machine.
        _jason = null;
      }

      WebUtils.onPanic((e) {
        Log.print('Panic: $e', 'Jason');
        _jason = null;
        _mediaManager = null;
      });
    }

    return _jason;
  }

  /// Returns the [MediaManagerHandle] instance of these [MediaUtils].
  static MediaManagerHandle? get mediaManager {
    _mediaManager ??= jason?.mediaManager();
    return _mediaManager;
  }

  /// Returns a [Stream] of the [MediaDeviceDetails] changes.
  static Stream<List<MediaDeviceDetails>> get onDeviceChange {
    if (_devicesController == null) {
      _devicesController = StreamController.broadcast();
      mediaManager?.onDeviceChange(() async {
        _devicesController?.add(
          (await mediaManager?.enumerateDevices() ?? [])
              .where((e) => e.deviceId().isNotEmpty)
              .toList(),
        );
      });
    }

    return _devicesController!.stream;
  }

  /// Returns a [Stream] of the [MediaDisplayDetails] changes.
  static Stream<List<MediaDisplayDetails>> get onDisplayChange {
    if (_displaysController == null) {
      _displaysController = StreamController.broadcast();

      if (!PlatformUtils.isWeb) {
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
  static Future<List<LocalMediaTrack>> getTracks({
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
  static Future<List<MediaDeviceDetails>> enumerateDevices([
    MediaDeviceKind? kind,
  ]) async {
    return (await mediaManager?.enumerateDevices() ?? [])
        .where((e) => e.deviceId().isNotEmpty)
        .where((e) => kind == null || e.kind() == kind)
        .toList();
  }

  /// Returns the currently available [MediaDisplayDetails].
  static Future<List<MediaDisplayDetails>> enumerateDisplays() async {
    if (PlatformUtils.isWeb) {
      return [];
    }

    return (await mediaManager?.enumerateDisplays() ?? [])
        .where((e) => e.deviceId().isNotEmpty)
        .toList();
  }

  /// Returns [MediaStreamSettings] with [audio], [video], [screen] enabled or
  /// not.
  static MediaStreamSettings _mediaStreamSettings({
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

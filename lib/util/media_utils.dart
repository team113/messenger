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
import 'web/web_utils.dart';

/// Helper providing direct access to media related resources like media
/// devices, media tracks, etc.
class MediaUtils {
  /// [Jason] communicating with the media resources.
  static Jason? _jason;

  /// [MediaManagerHandle] maintaining the media devices.
  static MediaManagerHandle? _mediaManager;

  /// [StreamController] of the [MediaDeviceDetails]s updating in the
  /// [MediaManagerHandle.onDeviceChange].
  static StreamController<List<MediaDeviceDetails>>? _devicesController;

  /// [StreamController] of the [MediaDisplayDetails]s updating in the
  /// [MediaManagerHandle.onDeviceChange].
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

  /// Returns a [Stream] of the [MediaDeviceDetails]s changes.
  static Stream<List<MediaDeviceDetails>> get onDeviceChange {
    if (_devicesController == null) {
      _devicesController = StreamController.broadcast();
      mediaManager?.onDeviceChange(() async {
        await _onDeviceChange();
      });
    }

    return _devicesController!.stream;
  }

  /// Returns a [Stream] of the [MediaDisplayDetails]s changes.
  static Stream<List<MediaDisplayDetails>> get onDisplayChange {
    if (_displaysController == null) {
      _displaysController = StreamController.broadcast();
      mediaManager?.onDeviceChange(() async {
        await _onDeviceChange();
      });
      _onDeviceChange();
    }

    return _displaysController!.stream;
  }

  /// Returns [LocalMediaTrack]s of the [audio], [video] and [screen] devices.
  static Future<List<LocalMediaTrack>> getTracks({
    TrackPreferences? audio,
    TrackPreferences? video,
    TrackPreferences? screen,
  }) async {
    if (mediaManager == null) {
      return [];
    }

    final List<LocalMediaTrack> tracks = [];

    // if (audio != null) {
    //   final LocalMediaTrack? track = _tracks.firstWhereOrNull(
    //     (e) =>
    //         e.kind() == MediaKind.Audio &&
    //         e.mediaSourceKind() == MediaSourceKind.Device &&
    //         (audio!.device == null || e.getTrack().deviceId() == audio.device),
    //   );

    //   if (track != null) {
    //     print('[MediaUtils] Re-use audio track: $track');
    //     tracks.add(track);
    //     audio = null;
    //   }
    // }

    if (audio != null || video != null || screen != null) {
      final List<LocalMediaTrack> local = await mediaManager!.initLocalTracks(
        _mediaStreamSettings(audio: audio, video: video, screen: screen),
      );

      tracks.addAll(local);
    }

    print('return ${tracks.map((e) => '${e.kind()} ${e.mediaSourceKind()}')}');

    return tracks;
  }

  /// Returns the [MediaDeviceDetails]s currently available with the provided
  /// [kind], if specified.
  static Future<List<MediaDeviceDetails>> enumerateDevices([
    MediaDeviceKind? kind,
  ]) async {
    return (await mediaManager?.enumerateDevices() ?? [])
        .where((e) => e.deviceId().isNotEmpty)
        .where((e) => kind == null || e.kind() == kind)
        .toList();
  }

  /// Returns the currently available [MediaDisplayDetails]s.
  static Future<List<MediaDisplayDetails>> enumerateDisplays() async {
    return (await mediaManager?.enumerateDisplays() ?? [])
        .where((e) => e.deviceId().isNotEmpty)
        .toList();
  }

  /// Returns [MediaStreamSettings] with [audio], [video], [screen] enabled or
  /// not.
  static MediaStreamSettings _mediaStreamSettings({
    TrackPreferences? audio,
    TrackPreferences? video,
    TrackPreferences? screen,
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

  /// Enumerates devices and displays and adds them to the [_devicesController]
  /// and [_displaysController].
  static Future<void> _onDeviceChange() async {
    print('MediaUtils _onDeviceChange');
    _devicesController?.add(
      (await mediaManager?.enumerateDevices() ?? [])
          .where((e) => e.deviceId().isNotEmpty)
          .toList(),
    );

    _displaysController?.add(
      (await mediaManager?.enumerateDisplays() ?? [])
          .where((e) => e.deviceId().isNotEmpty)
          .toList(),
    );
  }
}

/// A [LocalMediaTrack] reference.
class TrackPreferences {
  const TrackPreferences({
    this.device,
    this.facingMode,
    this.framerate,
  });

  /// ID of a device.
  final String? device;

  /// [FacingMode] of this [TrackPreferences].
  ///
  /// Used only for video tracks.
  final FacingMode? facingMode;

  /// Framerate of this [TrackPreferences].
  ///
  /// Used only for screen tracks.
  final int? framerate;
}

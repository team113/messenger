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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:mutex/mutex.dart';

import '/domain/model/media_settings.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/repository/settings.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of a [CameraSwitchView].
class CameraSwitchController extends GetxController {
  CameraSwitchController(this._settingsRepository, {String? camera})
      : camera = RxnString(camera);

  /// Settings repository updating the [MediaSettings.videoDevice].
  final AbstractSettingsRepository _settingsRepository;

  /// List of [MediaDeviceInfo] of all the available devices.
  InputDevices devices = RxList<MediaDeviceInfo>([]);

  /// ID of the initially selected video device.
  RxnString camera;

  /// [RtcVideoRenderer] rendering the currently selected [camera] device.
  final Rx<RtcVideoRenderer?> renderer = Rx<RtcVideoRenderer?>(null);

  /// Client for communicating with the [_mediaManager].
  Jason? _jason;

  /// Handle to a media manager tracking all the connected devices.
  MediaManagerHandle? _mediaManager;

  /// [LocalMediaTrack] of the currently selected [camera] device.
  LocalMediaTrack? _localTrack;

  /// [Worker] reacting on the [camera] changes updating the [renderer].
  Worker? _cameraWorker;

  /// Mutex guarding [initRenderer].
  final Mutex _initRendererGuard = Mutex();

  @override
  void onInit() async {
    _cameraWorker = ever(camera, (e) => initRenderer());

    try {
      _jason = Jason();
      _mediaManager = _jason?.mediaManager();
      _mediaManager?.onDeviceChange(() => _enumerateDevices());

      await WebUtils.cameraPermission();
      await _enumerateDevices();
    } catch (_) {
      // [Jason] may not be supported on the current platform.
      _jason = null;
      _mediaManager = null;
    }

    initRenderer();

    super.onInit();
  }

  @override
  void onClose() {
    _mediaManager?.free();
    _mediaManager = null;
    _jason?.free();
    _jason = null;
    renderer.value?.dispose();
    _localTrack?.free();
    _cameraWorker?.dispose();
    super.onClose();
  }

  /// Sets device with [id] as a used by default camera device.
  Future<void> setVideoDevice(String id) async {
    await _settingsRepository.setVideoDevice(id);
  }

  /// Initializes a [RtcVideoRenderer] for the current [camera].
  Future<void> initRenderer() async {
    if (_initRendererGuard.isLocked) {
      return;
    }

    renderer.value?.dispose();
    _localTrack?.free();

    final String? camera = this.camera.value;

    await _initRendererGuard.protect(() async {
      DeviceVideoTrackConstraints constraints = DeviceVideoTrackConstraints();
      if (camera != null) {
        constraints.deviceId(camera);
      }

      final settings = MediaStreamSettings()..deviceVideo(constraints);
      final List<LocalMediaTrack> tracks =
          await _mediaManager?.initLocalTracks(settings) ?? [];

      if (isClosed) {
        tracks.firstOrNull?.free();
        _localTrack = null;
      } else {
        _localTrack = tracks.firstOrNull;
      }

      if (_localTrack != null) {
        final RtcVideoRenderer renderer = RtcVideoRenderer(_localTrack!);
        await renderer.initialize();

        renderer.srcObject = tracks.first.getTrack();

        if (isClosed) {
          renderer.dispose();
          this.renderer.value = null;
        } else {
          this.renderer.value = renderer;
        }
      } else {
        renderer.value = null;
      }
    });

    if (camera != this.camera.value && !isClosed) {
      initRenderer();
    }
  }

  /// Populates [devices] with a list of [MediaDeviceInfo] objects representing
  /// available cameras.
  Future<void> _enumerateDevices() async {
    devices.value = ((await _mediaManager?.enumerateDevices() ?? []))
        .where(
          (e) =>
              e.deviceId().isNotEmpty && e.kind() == MediaDeviceKind.videoinput,
        )
        .toList();
  }
}

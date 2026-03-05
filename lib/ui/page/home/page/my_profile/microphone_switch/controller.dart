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

import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:mutex/mutex.dart';

import '/domain/model/media_settings.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';
import '/util/media_utils.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of a [MicrophoneSwitchView].
class MicrophoneSwitchController extends GetxController {
  MicrophoneSwitchController(this._settingsRepository, {String? mic})
    : _mic = RxnString(
        mic ?? _settingsRepository.mediaSettings.value?.audioDevice,
      );

  /// Settings repository updating the [MediaSettings.audioDevice].
  final AbstractSettingsRepository _settingsRepository;

  /// List of [DeviceDetails] of all the available devices.
  final RxList<DeviceDetails> devices = RxList([]);

  /// Currently selected [DeviceDetails].
  final Rx<DeviceDetails?> selected = Rx(null);

  /// Error message to display, if any.
  final RxnString error = RxnString();

  /// Audio input level of the currently selected microphone.
  final RxInt level = RxInt(0);

  /// ID of the initially selected microphone device.
  final RxnString _mic;

  /// [Worker] reacting on the [MediaSettings] changes updating the [selected].
  Worker? _worker;

  /// [StreamSubscription] for the [MediaUtilsImpl.onDeviceChange] stream
  /// updating the [devices].
  StreamSubscription? _devicesSubscription;

  /// [WebUtils.microphonePermission] subscription.
  StreamSubscription? _permissionSubscription;

  /// [LocalMediaTrack] of the currently selected [camera] device.
  LocalMediaTrack? _localTrack;

  /// [Worker] reacting on the [_mic] changes updating the [_localTrack].
  Worker? _micWorker;

  /// Mutex guarding [_initTrack].
  final Mutex _initGuard = Mutex();

  @override
  void onInit() async {
    _micWorker = ever(_mic, (e) => _initTrack());

    _devicesSubscription = MediaUtils.onDeviceChange.listen((e) {
      devices.value = e.audio().toList();
      selected.value = devices.firstWhereOrNull((e) => e.id() == _mic.value);

      if (_mic.value == 'default') {
        _initTrack();
      }
    });

    _worker = ever(_settingsRepository.mediaSettings, (e) {
      if (e != null) {
        _mic.value = e.audioDevice;
        selected.value = devices.firstWhereOrNull((e) => e.id() == _mic.value);
      }
    });

    try {
      _permissionSubscription = await WebUtils.microphonePermission();
      devices.value = await MediaUtils.enumerateDevices(
        MediaDeviceKind.audioInput,
      );
      selected.value = devices.firstWhereOrNull((e) => e.id() == _mic.value);
      _initTrack();
    } on UnsupportedError {
      error.value = 'err_media_devices_are_null'.l10n;
    } catch (e) {
      if (e.toString().contains('Permission denied')) {
        error.value = 'err_microphone_permission_denied'.l10n;
      } else {
        error.value = e.toString();
        rethrow;
      }
    }

    super.onInit();
  }

  @override
  void onClose() {
    _micWorker?.dispose();
    _devicesSubscription?.cancel();
    _permissionSubscription?.cancel();
    _worker?.dispose();
    _localTrack?.free();
    _localTrack = null;
    super.onClose();
  }

  /// Sets the provided [device] as a used by default microphone device.
  Future<void> setAudioDevice(DeviceDetails device) async {
    await _settingsRepository.setAudioDevice(device.id());
  }

  /// Initializes a [RtcVideoRenderer] for the current [_mic].
  Future<void> _initTrack() async {
    if (_initGuard.isLocked) {
      return;
    }

    level.value = 0;
    _localTrack?.free();
    _localTrack = null;

    String? mic = _mic.value;

    await _initGuard.protect(() async {
      final List<LocalMediaTrack> tracks = await MediaUtils.getTracks(
        audio: AudioPreferences(
          device: mic == 'default' ? null : mic,
          noiseSuppressionLevel:
              _settingsRepository.mediaSettings.value?.noiseSuppressionLevel,
          echoCancellation:
              _settingsRepository.mediaSettings.value?.echoCancellation,
          autoGainControl:
              _settingsRepository.mediaSettings.value?.autoGainControl,
          highPassFilter:
              _settingsRepository.mediaSettings.value?.highPassFilter,
        ),
      );

      if (isClosed) {
        tracks.firstOrNull?.free();
        _localTrack = null;
      } else {
        _localTrack = tracks.firstOrNull;
      }

      _localTrack?.onAudioLevelChanged((i) => level.value = i);
    });

    if (_mic.value != _mic.value && !isClosed) {
      _initTrack();
    }
  }
}

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

import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

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
      : _mic = RxnString(mic);

  /// Settings repository updating the [MediaSettings.audioDevice].
  final AbstractSettingsRepository _settingsRepository;

  /// List of [MediaDeviceDetails] of all the available devices.
  final RxList<MediaDeviceDetails> devices = RxList<MediaDeviceDetails>([]);

  /// Currently selected [MediaDeviceDetails].
  final Rx<MediaDeviceDetails?> selected = Rx<MediaDeviceDetails?>(null);

  /// Error message to display, if any.
  final RxnString error = RxnString();

  /// ID of the initially selected microphone device.
  final RxnString _mic;

  /// [StreamSubscription] for the [MediaUtils.onDeviceChange] stream updating
  /// the [devices].
  StreamSubscription? _devicesSubscription;

  @override
  void onInit() async {
    _devicesSubscription = MediaUtils.onDeviceChange.listen(
      (e) {
        devices.value = e.audio().toList();
        selected.value =
            devices.firstWhereOrNull((e) => e.deviceId() == _mic.value);
      },
    );

    _settingsRepository.mediaSettings.listen((e) {
      if (e != null) {
        _mic.value = e.audioDevice;
        selected.value =
            devices.firstWhereOrNull((e) => e.deviceId() == _mic.value);
      }
    });

    try {
      await WebUtils.microphonePermission();
      devices.value =
          await MediaUtils.enumerateDevices(MediaDeviceKind.audioInput);
      selected.value =
          devices.firstWhereOrNull((e) => e.deviceId() == _mic.value);
    } on UnsupportedError {
      error.value = 'err_media_devices_are_null'.l10n;
    } catch (e) {
      error.value = e.toString();
      rethrow;
    }

    super.onInit();
  }

  @override
  void onClose() {
    _devicesSubscription?.cancel();
    super.onClose();
  }

  /// Sets device with [id] as a used by default microphone device.
  Future<void> setAudioDevice(String id) async {
    await _settingsRepository.setAudioDevice(id);
  }
}

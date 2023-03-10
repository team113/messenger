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

import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/media_settings.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/repository/settings.dart';
import '/util/media_utils.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of a [MicrophoneSwitchView].
class MicrophoneSwitchController extends GetxController {
  MicrophoneSwitchController(this._settingsRepository, {String? mic})
      : mic = RxnString(mic);

  /// Settings repository updating the [MediaSettings.audioDevice].
  final AbstractSettingsRepository _settingsRepository;

  /// ID of the initially selected microphone device.
  RxnString mic;

  /// List of [MediaDeviceDetails] of all the available devices.
  final RxList<MediaDeviceDetails> devices = RxList<MediaDeviceDetails>([]);

  /// [StreamSubscription] for the [MediaUtils.onDeviceChange] stream updating
  /// the [devices].
  StreamSubscription? _devicesSubscription;

  @override
  void onInit() async {
    _devicesSubscription = MediaUtils.onDeviceChange.listen(
      (e) => devices.value =
          e.where((d) => d.kind() == MediaDeviceKind.AudioInput).toList(),
    );

    await WebUtils.microphonePermission();
    devices.value =
        await MediaUtils.enumerateDevices(MediaDeviceKind.AudioInput);

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

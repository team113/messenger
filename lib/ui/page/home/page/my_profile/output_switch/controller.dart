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

/// Controller of a [OutputSwitchView].
class OutputSwitchController extends GetxController {
  OutputSwitchController(this._settingsRepository, {String? output})
      : output = RxnString(output);

  /// Settings repository updating the [MediaSettings.outputDevice].
  final AbstractSettingsRepository _settingsRepository;

  /// List of [MediaDeviceDetails] of all the available devices.
  final RxList<MediaDeviceDetails> devices = RxList<MediaDeviceDetails>([]);

  /// ID of the initially selected audio output device.
  RxnString output;

  /// [StreamSubscription] for the [MediaUtils.onDeviceChange] stream updating
  /// the [devices].
  StreamSubscription? _devicesSubscription;

  @override
  void onInit() async {
    _devicesSubscription = MediaUtils.onDeviceChange.listen(
      (e) => devices.value = e.output().toList(),
    );

    // Output devices are permitted to be use when requesting a microphone
    // permission.
    await WebUtils.microphonePermission();
    devices.value =
        await MediaUtils.enumerateDevices(MediaDeviceKind.audioOutput);

    super.onInit();
  }

  @override
  void onClose() {
    _devicesSubscription?.cancel();
    super.onClose();
  }

  /// Sets device with [id] as a used by default output device.
  Future<void> setOutputDevice(String id) async {
    await _settingsRepository.setOutputDevice(id);
  }
}

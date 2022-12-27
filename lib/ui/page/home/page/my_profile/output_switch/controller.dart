// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

export 'view.dart';

/// Controller of a [OutputSwitchView].
class OutputSwitchController extends GetxController {
  OutputSwitchController(this._call, this._settingsRepository);

  /// Local [OngoingCall] for enumerating and displaying local media.
  final Rx<OngoingCall> _call;

  /// Settings repository updating the [MediaSettings.outputDevice].
  final AbstractSettingsRepository _settingsRepository;

  /// Returns a list of [MediaDeviceInfo] of all the available devices.
  InputDevices get devices => _call.value.devices;

  /// Returns ID of the currently used video device.
  RxnString get output => _call.value.outputDevice;

  @override
  void onInit() {
    _call.value.setAudioEnabled(true);
    super.onInit();
  }

  @override
  void onClose() {
    _call.value.setAudioEnabled(false);
    super.onClose();
  }

  /// Sets device with [id] as a used by default output device.
  Future<void> setOutputDevice(String id) async {
    await Future.wait([
      _call.value.setOutputDevice(id),
      _settingsRepository.setOutputDevice(id),
    ]);
  }
}

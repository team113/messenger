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

import '/domain/model/media_settings.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';
import '/util/media_utils.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of a [OutputSwitchView].
class OutputSwitchController extends GetxController {
  OutputSwitchController(this._settingsRepository, {String? output})
    : _output = output ?? _settingsRepository.mediaSettings.value?.outputDevice;

  /// Settings repository updating the [MediaSettings.outputDevice].
  final AbstractSettingsRepository _settingsRepository;

  /// List of [DeviceDetails] of all the available devices.
  final RxList<DeviceDetails> devices = RxList<DeviceDetails>([]);

  /// Currently selected [DeviceDetails].
  final Rx<DeviceDetails?> selected = Rx<DeviceDetails?>(null);

  /// Error message to display, if any.
  final RxnString error = RxnString();

  /// ID of the initially selected audio output device.
  String? _output;

  /// [Worker] reacting on the [MediaSettings] changes updating the [selected].
  Worker? _worker;

  /// [StreamSubscription] for the [MediaUtilsImpl.onDeviceChange] stream
  /// updating the [devices].
  StreamSubscription? _devicesSubscription;

  /// [WebUtils.microphonePermission] subscription.
  StreamSubscription? _permissionSubscription;

  @override
  void onInit() async {
    _devicesSubscription = MediaUtils.onDeviceChange.listen((e) {
      devices.value = e.output().toList();
      selected.value = devices.firstWhereOrNull((e) => e.id() == _output);
    });

    _worker = ever(_settingsRepository.mediaSettings, (e) {
      if (e != null) {
        _output = e.outputDevice;

        selected.value = devices.firstWhereOrNull((e) => e.id() == _output);
      }
    });

    try {
      // Output devices are permitted to be use when requesting a microphone
      // permission.
      _permissionSubscription = await WebUtils.microphonePermission();
      devices.value = await MediaUtils.enumerateDevices(
        MediaDeviceKind.audioOutput,
      );
      selected.value = devices.firstWhereOrNull((e) => e.id() == _output);
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
    _devicesSubscription?.cancel();
    _permissionSubscription?.cancel();
    _worker?.dispose();
    super.onClose();
  }

  /// Sets the provided [device] as a used by default output device.
  Future<void> setOutputDevice(DeviceDetails device) async {
    await _settingsRepository.setOutputDevice(device.id());
  }
}

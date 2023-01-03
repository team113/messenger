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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/media_settings.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/repository/settings.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of a [MicrophoneSwitchView].
class MicrophoneSwitchController extends GetxController {
  MicrophoneSwitchController(this._settingsRepository, {String? mic})
      : mic = RxnString(mic);

  /// Settings repository updating the [MediaSettings.audioDevice].
  final AbstractSettingsRepository _settingsRepository;

  /// List of [MediaDeviceInfo] of all the available devices.
  InputDevices devices = RxList<MediaDeviceInfo>([]);

  /// ID of the currently used microphone device.
  RxnString mic;

  /// Client for communication with a media server.
  Jason? _jason;

  /// Handle to a media manager tracking all the connected devices.
  MediaManagerHandle? _mediaManager;

  @override
  void onInit() async {
    _jason = Jason();

    _mediaManager = _jason!.mediaManager();
    _mediaManager!.onDeviceChange(() async {
      await _enumerateDevices();
    });

    await WebUtils.audioPermission();

    _enumerateDevices();
    super.onInit();
  }

  @override
  void onClose() {
    _mediaManager?.free();
    _jason?.free();
    super.onClose();
  }

  /// Sets device with [id] as a used by default microphone device.
  Future<void> setAudioDevice(String id) async {
    await _settingsRepository.setAudioDevice(id);
  }

  /// Populates [devices] with a list of [MediaDeviceInfo] objects representing
  /// available media input devices, such as microphones, cameras, and so forth.
  Future<void> _enumerateDevices() async {
    devices.value = (await _mediaManager!.enumerateDevices())
        .whereNot((e) => e.deviceId().isEmpty)
        .toList();
    devices.refresh();
  }
}

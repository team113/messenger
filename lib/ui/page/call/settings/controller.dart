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

import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/ongoing_call.dart';
import '/domain/repository/settings.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the call overlay settings.
class CallSettingsController extends GetxController {
  CallSettingsController(this._call, this._settingsRepo, {required this.onPop});

  /// The [OngoingCall] that this settings are bound to.
  final Rx<OngoingCall> _call;

  /// Settings repository, used to update the [MediaSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// Returns the local [Track]s.
  ObsList<Track>? get localTracks => _call.value.localTracks;

  /// Returns a list of [MediaDeviceInfo] of all the available devices.
  InputDevices get devices => _call.value.devices;

  /// Returns ID of the currently used video device.
  RxnString get videoDevice => _call.value.videoDevice;

  /// Returns ID of the currently used microphone device.
  RxnString get audioDevice => _call.value.audioDevice;

  /// Returns ID of the currently used output device.
  RxnString get outputDevice => _call.value.outputDevice;

  /// Callback to pop the [CallSettingsView].
  void Function() onPop;

  /// Worker for catching the [OngoingCallState.ended] state of the call to pop
  /// the settings.
  late Worker _stateWorker;

  @override
  void onReady() {
    super.onReady();
    _call.value.enumerateDevices();
    _stateWorker = ever(_call.value.state, (state) {
      if (state == OngoingCallState.ended) {
        onPop();
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    _stateWorker.dispose();
  }

  /// Sets device with [id] as a used by default [videoDevice].
  void setVideoDevice(String id) {
    _call.value.setVideoDevice(id);
    _settingsRepo.setVideoDevice(id);
  }

  /// Sets device with [id] as a used by default [audioDevice].
  void setAudioDevice(String id) {
    _call.value.setAudioDevice(id);
    _settingsRepo.setAudioDevice(id);
  }

  /// Sets device with [id] as a used by default [outputDevice].
  void setOutputDevice(String id) {
    _call.value.setOutputDevice(id);
    _settingsRepo.setOutputDevice(id);
  }
}

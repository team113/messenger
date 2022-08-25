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

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/media_settings.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the [Routes.settingsMedia] page.
class MediaSettingsController extends GetxController {
  MediaSettingsController(this._settingsRepo);

  /// Local [OngoingCall] for enumerating and displaying local media.
  late final Rx<OngoingCall> _call;

  /// Settings repository, used to update the [MediaSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// [StreamSubscription] to the [OngoingCall.localTracks] disposing the
  /// removed [Track]s.
  late final StreamSubscription? _localTracks;

  /// Returns local video tracks.
  ObsList<Track>? get localTracks => _call.value.localTracks;

  /// Returns a list of [MediaDeviceInfo] of all the available devices.
  InputDevices get devices => _call.value.devices;

  /// Returns ID of the currently used video device.
  RxnString get camera => _call.value.videoDevice;

  /// Returns ID of the currently used microphone device.
  RxnString get mic => _call.value.audioDevice;

  /// Returns ID of the currently used output device.
  RxnString get output => _call.value.outputDevice;

  @override
  void onInit() {
    super.onInit();
    // TODO: This is a really bad hack. We should not create call here. Required
    //       functionality should be decoupled from the OngoingCall or
    //       reimplemented here.
    _call = Rx<OngoingCall>(OngoingCall(
      const ChatId('settings'),
      const UserId(''),
      state: OngoingCallState.local,
      mediaSettings: _settingsRepo.mediaSettings.value,
    ));

    _localTracks = _call.value.localTracks?.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          // No-op.
          break;

        case OperationKind.removed:
          SchedulerBinding.instance
              .addPostFrameCallback((_) => e.element.dispose());
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    _call.value.init();
  }

  @override
  void onClose() {
    super.onClose();

    _localTracks?.cancel();
    _call.value.dispose();
  }

  /// Sets device with [id] as a used by default [camera] device.
  void setVideoDevice(String id) {
    _call.value.setVideoDevice(id);
    _settingsRepo.setVideoDevice(id);
  }

  /// Sets device with [id] as a used by default [mic] device.
  void setAudioDevice(String id) {
    _call.value.setAudioDevice(id);
    _settingsRepo.setAudioDevice(id);
  }

  /// Sets device with [id] as a used by default [output] device.
  void setOutputDevice(String id) {
    _call.value.setOutputDevice(id);
    _settingsRepo.setOutputDevice(id);
  }
}

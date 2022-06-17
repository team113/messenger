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
import 'package:hive/hive.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/media_settings.dart';
import '/domain/repository/settings.dart';
import '/provider/hive/application_settings.dart';
import '/provider/hive/media_settings.dart';

/// Application settings repository.
class SettingsRepository extends DisposableInterface
    implements AbstractSettingsRepository {
  SettingsRepository(this._mediaLocal, this._settingsLocal);

  @override
  final Rx<MediaSettings?> mediaSettings = Rx(null);

  @override
  final Rx<ApplicationSettings?> applicationSettings = Rx(null);

  /// [MediaSettings] local [Hive] storage.
  final MediaSettingsHiveProvider _mediaLocal;

  /// [ApplicationSettings] local [Hive] storage.
  final ApplicationSettingsHiveProvider _settingsLocal;

  /// [MediaSettingsHiveProvider.boxEvents] subscription.
  StreamIterator? _mediaSubscription;

  /// [ApplicationSettingsHiveProvider.boxEvents] subscription.
  StreamIterator? _settingsSubscription;

  @override
  void onInit() {
    mediaSettings.value = _mediaLocal.settings;
    applicationSettings.value = _settingsLocal.settings;
    _initMediaSubscription();
    _initSettingsSubscription();
    super.onInit();
  }

  @override
  void onClose() {
    _mediaSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.onClose();
  }

  @override
  Future<void> clearCache() => _mediaLocal.clear();

  @override
  Future<void> setVideoDevice(String id) => _mediaLocal.setVideoDevice(id);

  @override
  Future<void> setAudioDevice(String id) => _mediaLocal.setAudioDevice(id);

  @override
  Future<void> setOutputDevice(String id) => _mediaLocal.setOutputDevice(id);

  @override
  Future<void> setPopupsEnabled(bool enabled) =>
      _settingsLocal.setPopupsEnabled(enabled);

  /// Initializes [MediaSettingsHiveProvider.boxEvents] subscription.
  Future<void> _initMediaSubscription() async {
    _mediaSubscription = StreamIterator(_mediaLocal.boxEvents);
    while (await _mediaSubscription!.moveNext()) {
      BoxEvent event = _mediaSubscription!.current;
      if (event.deleted) {
        mediaSettings.value = null;
      } else {
        mediaSettings.value = event.value;
        mediaSettings.refresh();
      }
    }
  }

  /// Initializes [ApplicationSettingsHiveProvider.boxEvents] subscription.
  Future<void> _initSettingsSubscription() async {
    _settingsSubscription = StreamIterator(_settingsLocal.boxEvents);
    while (await _settingsSubscription!.moveNext()) {
      BoxEvent event = _settingsSubscription!.current;
      if (event.deleted) {
        applicationSettings.value = null;
      } else {
        applicationSettings.value = event.value;
        applicationSettings.refresh();
      }
    }
  }
}

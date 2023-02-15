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
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/chat.dart';
import '/domain/model/media_settings.dart';
import '/domain/repository/settings.dart';
import '/provider/hive/application_settings.dart';
import '/provider/hive/background.dart';
import '/provider/hive/calls_preferences.dart';
import '/provider/hive/media_settings.dart';

/// Application settings repository.
class SettingsRepository extends DisposableInterface
    implements AbstractSettingsRepository {
  SettingsRepository(
    this._mediaLocal,
    this._settingsLocal,
    this._backgroundLocal,
    this._callsSettingsProvider,
  );

  @override
  final Rx<MediaSettings?> mediaSettings = Rx(null);

  @override
  final Rx<ApplicationSettings?> applicationSettings = Rx(null);

  @override
  final Rx<Uint8List?> background = Rx(null);

  /// [MediaSettings] local [Hive] storage.
  final MediaSettingsHiveProvider _mediaLocal;

  /// [ApplicationSettings] local [Hive] storage.
  final ApplicationSettingsHiveProvider _settingsLocal;

  /// [HiveBackground] local [Hive] storage.
  final BackgroundHiveProvider _backgroundLocal;

  /// [CallsPreferencesHiveProvider] persisting and returns chats call [Rect]
  /// info.
  final CallsPreferencesHiveProvider _callsSettingsProvider;

  /// [MediaSettingsHiveProvider.boxEvents] subscription.
  StreamIterator? _mediaSubscription;

  /// [ApplicationSettingsHiveProvider.boxEvents] subscription.
  StreamIterator? _settingsSubscription;

  /// [BackgroundHiveProvider.boxEvents] subscription.
  StreamIterator? _backgroundSubscription;

  @override
  void onInit() {
    mediaSettings.value = _mediaLocal.settings;
    applicationSettings.value = _settingsLocal.settings;
    background.value = _backgroundLocal.bytes;
    _initMediaSubscription();
    _initSettingsSubscription();
    _initBackgroundSubscription();

    super.onInit();
  }

  @override
  void onClose() {
    _mediaSubscription?.cancel();
    _settingsSubscription?.cancel();
    _backgroundSubscription?.cancel();
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

  @override
  Future<void> setLocale(String locale) => _settingsLocal.setLocale(locale);

  @override
  Future<void> setShowIntroduction(bool show) =>
      _settingsLocal.setShowIntroduction(show);

  @override
  Future<void> setSideBarWidth(double width) =>
      _settingsLocal.setSideBarWidth(width);

  @override
  Future<void> setBackground(Uint8List? bytes) =>
      bytes == null ? _backgroundLocal.delete() : _backgroundLocal.set(bytes);

  @override
  Future<void> setCallButtons(List<String> buttons) =>
      _settingsLocal.setCallButtons(buttons);

  @override
  Future<void> setShowDragAndDropVideosHint(bool show) =>
      _settingsLocal.setShowDragAndDropVideosHint(show);

  @override
  Future<void> setShowDragAndDropButtonsHint(bool show) =>
      _settingsLocal.setShowDragAndDropButtonsHint(show);

  @override
  Future<void> setSortContactsByName(bool enabled) =>
      _settingsLocal.setSortContactsByName(enabled);

  @override
  Future<void> setCallPrefs(ChatId chatId, Rect prefs) =>
      _callsSettingsProvider.put(chatId, prefs);

  @override
  Rect? getCallPrefs(ChatId id) => _callsSettingsProvider.get(id);

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

  /// Initializes [BackgroundHiveProvider.boxEvents] subscription.
  Future<void> _initBackgroundSubscription() async {
    _backgroundSubscription = StreamIterator(_backgroundLocal.boxEvents);
    while (await _backgroundSubscription!.moveNext()) {
      BoxEvent event = _backgroundSubscription!.current;
      if (event.deleted) {
        background.value = null;
      } else {
        background.value = event.value.bytes;
        background.refresh();
      }
    }
  }
}

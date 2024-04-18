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
import 'dart:typed_data';

import 'package:flutter/material.dart' show Rect;
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/chat.dart';
import '/domain/model/media_settings.dart';
import '/domain/repository/settings.dart';
import '/provider/hive/application_settings.dart';
import '/provider/hive/background.dart';
import '/provider/hive/call_rect.dart';
import '/provider/hive/media_settings.dart';
import '/util/log.dart';

/// Application settings repository.
class SettingsRepository extends DisposableInterface
    implements AbstractSettingsRepository {
  SettingsRepository(
    this._mediaLocal,
    this._settingsLocal,
    this._backgroundLocal,
    this._callRectLocal,
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

  /// [CallRectHiveProvider] persisting the [Rect] preferences of the
  /// [OngoingCall]s.
  final CallRectHiveProvider _callRectLocal;

  /// [MediaSettingsHiveProvider.boxEvents] subscription.
  StreamIterator? _mediaSubscription;

  /// [ApplicationSettingsHiveProvider.boxEvents] subscription.
  StreamIterator? _settingsSubscription;

  /// [BackgroundHiveProvider.boxEvents] subscription.
  StreamIterator? _backgroundSubscription;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

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
    Log.debug('onClose()', '$runtimeType');

    _mediaSubscription?.cancel();
    _settingsSubscription?.cancel();
    _backgroundSubscription?.cancel();
    super.onClose();
  }

  @override
  Future<void> clearCache() async {
    Log.debug('clearCache()', '$runtimeType');
    await _mediaLocal.clear();
  }

  @override
  Future<void> setVideoDevice(String id) async {
    Log.debug('setVideoDevice($id)', '$runtimeType');
    await _mediaLocal.setVideoDevice(id);
  }

  @override
  Future<void> setAudioDevice(String id) async {
    Log.debug('setAudioDevice($id)', '$runtimeType');
    await _mediaLocal.setAudioDevice(id);
  }

  @override
  Future<void> setOutputDevice(String id) async {
    Log.debug('setOutputDevice($id)', '$runtimeType');
    await _mediaLocal.setOutputDevice(id);
  }

  @override
  Future<void> setPopupsEnabled(bool enabled) async {
    Log.debug('setPopupsEnabled($enabled)', '$runtimeType');
    await _settingsLocal.setPopupsEnabled(enabled);
  }

  @override
  Future<void> setLocale(String locale) async {
    Log.debug('setLocale($locale)', '$runtimeType');
    await _settingsLocal.setLocale(locale);
  }

  @override
  Future<void> setShowIntroduction(bool show) async {
    Log.debug('setShowIntroduction($show)', '$runtimeType');
    await _settingsLocal.setShowIntroduction(show);
  }

  @override
  Future<void> setSideBarWidth(double width) async {
    Log.debug('setSideBarWidth($width)', '$runtimeType');
    await _settingsLocal.setSideBarWidth(width);
  }

  @override
  Future<void> setBackground(Uint8List? bytes) async {
    Log.debug('setBackground(${bytes?.length})', '$runtimeType');

    bytes == null
        ? await _backgroundLocal.delete()
        : await _backgroundLocal.set(bytes);
  }

  @override
  Future<void> setCallButtons(List<String> buttons) async {
    Log.debug('setCallButtons($buttons)', '$runtimeType');
    await _settingsLocal.setCallButtons(buttons);
  }

  @override
  Future<void> setShowDragAndDropVideosHint(bool show) async {
    Log.debug('setShowDragAndDropVideosHint($show)', '$runtimeType');
    await _settingsLocal.setShowDragAndDropVideosHint(show);
  }

  @override
  Future<void> setShowDragAndDropButtonsHint(bool show) async {
    Log.debug('setShowDragAndDropButtonsHint($show)', '$runtimeType');
    await _settingsLocal.setShowDragAndDropButtonsHint(show);
  }

  @override
  Future<void> setCallRect(ChatId chatId, Rect prefs) async {
    Log.debug('setCallRect($chatId, $prefs)', '$runtimeType');
    await _callRectLocal.put(chatId, prefs);
  }

  @override
  Rect? getCallRect(ChatId id) {
    Log.debug('getCallRect($id)', '$runtimeType');
    return _callRectLocal.get(id);
  }

  @override
  Future<void> setPinnedActions(List<String> buttons) async {
    Log.debug('setPinnedActions($buttons)', '$runtimeType');
    await _settingsLocal.setPinnedActions(buttons);
  }

  @override
  Future<void> setCallButtonsPosition(CallButtonsPosition position) async {
    Log.debug('setCallButtonsPosition($position)', '$runtimeType');
    await _settingsLocal.setCallButtonsPosition(position);
  }

  @override
  Future<void> setWorkWithUsTabEnabled(bool enabled) async {
    Log.debug('setWorkWithUsTabEnabled($enabled)', '$runtimeType');
    await _settingsLocal.setWorkWithUsTabEnabled(enabled);
  }

  @override
  Future<void> setContactsImported(bool val) async {
    Log.debug('setContactsImported($val)', '$runtimeType');
    await _settingsLocal.setContactsImported(val);
  }

  /// Initializes [MediaSettingsHiveProvider.boxEvents] subscription.
  Future<void> _initMediaSubscription() async {
    Log.debug('_initMediaSubscription()', '$runtimeType');

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
    Log.debug('_initSettingsSubscription()', '$runtimeType');

    _settingsSubscription = StreamIterator(_settingsLocal.boxEvents);
    while (await _settingsSubscription!.moveNext()) {
      final BoxEvent event = _settingsSubscription!.current;
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
    Log.debug('_initBackgroundSubscription()', '$runtimeType');

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

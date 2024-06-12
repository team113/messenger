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
import 'package:mutex/mutex.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/chat.dart';
import '/domain/model/media_settings.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/provider/drift/background.dart';
import '/provider/drift/call_rect.dart';
import '/provider/drift/settings.dart';
import '/util/log.dart';
import 'model/background.dart';

/// Application settings repository.
class SettingsRepository extends DisposableInterface
    implements AbstractSettingsRepository {
  SettingsRepository(
    this.userId,
    this._settingsLocal,
    this._backgroundLocal,
    this._callRectLocal,
  );

  /// [UserId] to track [ApplicationSettings] of.
  final UserId userId;

  @override
  final Rx<MediaSettings?> mediaSettings = Rx(null);

  @override
  final Rx<ApplicationSettings?> applicationSettings = Rx(null);

  @override
  final Rx<Uint8List?> background = Rx(null);

  /// [ApplicationSettings] and [MediaSettings] local storage.
  final SettingsDriftProvider _settingsLocal;

  /// [DtoBackground] local storage.
  final BackgroundDriftProvider _backgroundLocal;

  /// [CallRectDriftProvider] persisting the [Rect] preferences of the
  /// [OngoingCall]s.
  final CallRectDriftProvider _callRectLocal;

  /// [SettingsDriftProvider.watch] subscription.
  StreamSubscription? _settingsSubscription;

  /// [BackgroundDriftProvider.watch] subscription.
  StreamSubscription? _backgroundSubscription;

  /// [Mutex] guarding [_set]ting of the values before they were read.
  final Mutex _guard = Mutex();

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    _guard.protect(() async {
      final DtoSettings? settings = await _settingsLocal.read(userId);
      mediaSettings.value = settings?.media;
      applicationSettings.value = settings?.application;

      final DtoBackground? bytes = await _backgroundLocal.read(userId);
      background.value = bytes?.bytes;
    });

    _initSettingsSubscription();
    _initBackgroundSubscription();

    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    _settingsSubscription?.cancel();
    _backgroundSubscription?.cancel();
    super.onClose();
  }

  @override
  Future<void> clearCache() async {
    Log.debug('clearCache()', '$runtimeType');
    await _settingsLocal.clear();
  }

  @override
  Future<void> setVideoDevice(String id) async {
    Log.debug('setVideoDevice($id)', '$runtimeType');
    await _set(media: (e) => e..videoDevice = id);
  }

  @override
  Future<void> setAudioDevice(String id) async {
    Log.debug('setAudioDevice($id)', '$runtimeType');
    await _set(media: (e) => e..audioDevice = id);
  }

  @override
  Future<void> setOutputDevice(String id) async {
    Log.debug('setOutputDevice($id)', '$runtimeType');
    await _set(media: (e) => e..outputDevice = id);
  }

  @override
  Future<void> setPopupsEnabled(bool enabled) async {
    Log.debug('setPopupsEnabled($enabled)', '$runtimeType');
    await _set(settings: (e) => e..enablePopups = enabled);
  }

  @override
  Future<void> setLocale(String locale) async {
    Log.debug('setLocale($locale)', '$runtimeType');
    await _set(settings: (e) => e..locale = locale);
  }

  @override
  Future<void> setShowIntroduction(bool show) async {
    Log.debug('setShowIntroduction($show)', '$runtimeType');
    await _set(settings: (e) => e..showIntroduction = show);
  }

  @override
  Future<void> setSideBarWidth(double width) async {
    Log.debug('setSideBarWidth($width)', '$runtimeType');
    await _set(settings: (e) => e..sideBarWidth = width);
  }

  @override
  Future<void> setBackground(Uint8List? bytes) async {
    Log.debug('setBackground(${bytes?.length})', '$runtimeType');

    bytes == null
        ? await _backgroundLocal.delete(userId)
        : await _backgroundLocal.upsert(userId, DtoBackground(bytes));
  }

  @override
  Future<void> setCallButtons(List<String> buttons) async {
    Log.debug('setCallButtons($buttons)', '$runtimeType');
    await _set(settings: (e) => e..callButtons = buttons);
  }

  @override
  Future<void> setShowDragAndDropVideosHint(bool show) async {
    Log.debug('setShowDragAndDropVideosHint($show)', '$runtimeType');

    // No-op.
  }

  @override
  Future<void> setShowDragAndDropButtonsHint(bool show) async {
    Log.debug('setShowDragAndDropButtonsHint($show)', '$runtimeType');

    // No-op.
  }

  @override
  Future<void> setCallRect(ChatId chatId, Rect prefs) async {
    Log.debug('setCallRect($chatId, $prefs)', '$runtimeType');
    await _callRectLocal.upsert(chatId, prefs);
  }

  @override
  Future<Rect?> getCallRect(ChatId id) async {
    Log.debug('getCallRect($id)', '$runtimeType');
    return await _callRectLocal.read(id);
  }

  @override
  Future<void> setPinnedActions(List<String> buttons) async {
    Log.debug('setPinnedActions($buttons)', '$runtimeType');
    await _set(settings: (e) => e..pinnedActions = buttons);
  }

  @override
  Future<void> setCallButtonsPosition(CallButtonsPosition position) async {
    Log.debug('setCallButtonsPosition($position)', '$runtimeType');
    await _set(settings: (e) => e..callButtonsPosition = position);
  }

  @override
  Future<void> setWorkWithUsTabEnabled(bool enabled) async {
    Log.debug('setWorkWithUsTabEnabled($enabled)', '$runtimeType');
    await _set(settings: (e) => e..workWithUsTabEnabled = enabled);
  }

  /// Stores the provided [ApplicationSettings] and [MediaSettings] to the local
  /// storage.
  Future<void> _set({
    ApplicationSettings? Function(ApplicationSettings)? settings,
    MediaSettings? Function(MediaSettings)? media,
  }) async {
    if (_guard.isLocked) {
      await _guard.protect(() async {});
    }

    applicationSettings.value =
        settings?.call(applicationSettings.value ?? ApplicationSettings()) ??
            applicationSettings.value;

    mediaSettings.value = media?.call(mediaSettings.value ?? MediaSettings()) ??
        mediaSettings.value;

    await _settingsLocal.upsert(
      userId,
      DtoSettings(
        application: applicationSettings.value ?? ApplicationSettings(),
        media: mediaSettings.value ?? MediaSettings(),
      ),
    );
  }

  /// Initializes [SettingsDriftProvider.watch] subscription.
  Future<void> _initSettingsSubscription() async {
    Log.debug('_initSettingsSubscription()', '$runtimeType');

    _settingsSubscription = _settingsLocal.watch(userId).listen((e) {
      applicationSettings.value = e?.application;
      mediaSettings.value = e?.media;
    });
  }

  /// Initializes [BackgroundDriftProvider.watch] subscription.
  Future<void> _initBackgroundSubscription() async {
    Log.debug('_initBackgroundSubscription()', '$runtimeType');

    _settingsSubscription = _backgroundLocal.watch(userId).listen((e) {
      background.value = e?.bytes;
    });
  }
}

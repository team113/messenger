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

import 'dart:typed_data';

import 'package:flutter/material.dart' show Rect;
import 'package:get/get.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/chat.dart';
import '/domain/model/media_settings.dart';

/// Application settings repository interface.
abstract class AbstractSettingsRepository {
  /// Returns the stored [MediaSettings].
  Rx<MediaSettings?> get mediaSettings;

  /// Returns the stored [ApplicationSettings].
  Rx<ApplicationSettings?> get applicationSettings;

  /// Returns the stored [Uint8List] of the background.
  Rx<Uint8List?> get background;

  /// Clears the stored settings.
  Future<void> clearCache();

  /// Sets the [MediaSettings.videoDevice] value.
  Future<void> setVideoDevice(String id);

  /// Sets the [MediaSettings.audioDevice] value.
  Future<void> setAudioDevice(String id);

  /// Sets the [MediaSettings.outputDevice] value.
  Future<void> setOutputDevice(String id);

  /// Sets the [ApplicationSettings.enablePopups] value.
  Future<void> setPopupsEnabled(bool enabled);

  /// Sets the [ApplicationSettings.locale] value.
  Future<void> setLocale(String locale);

  /// Sets the [ApplicationSettings.showIntroduction] value.
  Future<void> setShowIntroduction(bool show);

  /// Sets the [ApplicationSettings.sideBarWidth] value.
  Future<void> setSideBarWidth(double width);

  /// Sets the [background] value.
  Future<void> setBackground(Uint8List? bytes);

  /// Sets the [ApplicationSettings.callButtons] value.
  Future<void> setCallButtons(List<String> buttons);

  /// Sets the [ApplicationSettings.showDragAndDropVideosHint] value.
  Future<void> setShowDragAndDropVideosHint(bool show);

  /// Sets the [ApplicationSettings.showDragAndDropButtonsHint] value.
  Future<void> setShowDragAndDropButtonsHint(bool show);

  /// Sets the [ApplicationSettings.sortContactsByName] value.
  Future<void> setSortContactsByName(bool enabled);

  /// Sets the [ApplicationSettings.loadImages] value.
  Future<void> setLoadImages(bool enabled);

  /// Sets the provided [Rect] preferences of an [OngoingCall] happening in the
  /// specified [Chat].
  Future<void> setCallRect(ChatId chatId, Rect prefs);

  /// Returns the [Rect] preferences of an [OngoingCall] happening in the
  /// specified [Chat].
  Rect? getCallRect(ChatId id);

  /// Sets the [ApplicationSettings.displayFunds] value.
  Future<void> setDisplayFunds(bool enabled);

  /// Sets the [ApplicationSettings.displayTransactions] value.
  Future<void> setDisplayTransactions(bool enabled);
}

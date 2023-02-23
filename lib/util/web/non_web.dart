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

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show NotificationResponse;
import 'package:permission_handler/permission_handler.dart';

import '/domain/model/chat.dart';
import '/domain/model/session.dart';
import 'web_utils.dart';

/// Helper providing direct access to browser-only features.
///
/// Does nothing on desktop or mobile.
class WebUtils {
  /// Callback, called when user taps onto a notification.
  static void Function(NotificationResponse)? onSelectNotification;

  /// Indicates whether device's OS is macOS or iOS.
  static bool get isMacOS => false;

  /// Indicates whether device's browser is Safari or not.
  static bool get isSafari => false;

  /// Indicates whether device's browser is in fullscreen mode or not.
  static bool get isFullscreen => false;

  /// Indicates whether device's browser is in focus.
  static bool get isFocused => false;

  /// Returns a stream broadcasting the fullscreen changes.
  static Stream<bool> get onFullscreenChange => const Stream.empty();

  /// Returns a stream broadcasting the browser's storage changes.
  static Stream<WebStorageEvent> get onStorageChange => const Stream.empty();

  /// Returns a stream broadcasting the device's browser focus changes.
  static Stream<bool> get onFocusChanged => const Stream.empty();

  /// Returns a stream broadcasting the browser's window focus changes.
  static Stream<bool> get onWindowFocus => const Stream.empty();

  /// Sets the provided [Credentials] to the browser's storage.
  static set credentials(Credentials? creds) {
    // No-op.
  }

  /// Returns the stored in browser's storage [Credentials].
  static Credentials? get credentials => null;

  /// Indicates whether the current window is a popup.
  static bool get isPopup => false;

  /// Pushes [title] to browser's window title.
  static void title(String title) {
    // No-op.
  }

  /// Sets the URL strategy of your web app to using paths instead of a leading
  /// hash (`#`).
  static void setPathUrlStrategy() {
    // No-op.
  }

  // TODO: Styles page related, should be removed at some point.
  /// Downloads the file from [url] and saves it as [filename].
  static Future<void> download(String url, String filename) async {
    // No-op.
  }

  /// Toggles browser's fullscreen to [enable], and returns the resulting
  /// fullscreen state.
  ///
  /// Always returns `false` if fullscreen is not supported.
  static bool toggleFullscreen(bool enable) => false;

  /// Shows a notification via "Notification API" of the browser.
  static Future<void> showNotification(
    String title, {
    String? dir,
    String? body,
    String? lang,
    String? tag,
    String? icon,
  }) async {
    // No-op.
  }

  /// Does nothing as `IndexedDB` is absent on desktop or mobile platforms.
  static Future<void> cleanIndexedDb() async {
    // No-op.
  }

  /// Clears the browser's storage.
  static void cleanStorage() {
    // No-op.
  }

  /// Opens a new popup window at the [Routes.call] page with the provided
  /// [chatId].
  static bool openPopupCall(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = false,
    bool withScreen = false,
  }) =>
      false;

  /// Closes the current window.
  static void closeWindow() {
    // No-op.
  }

  /// Returns a call identified by the provided [chatId] from the browser's
  /// storage.
  static WebStoredCall? getCall(ChatId chatId) => null;

  /// Stores the provided [call] in the browser's storage.
  static void setCall(WebStoredCall call) {
    // No-op.
  }

  /// Removes a call identified by the provided [chatId] from the browser's
  /// storage.
  static void removeCall(ChatId chatId) {
    // No-op.
  }

  /// Moves a call identified by its [chatId] to the [newChatId] replacing its
  /// stored state with an optional [newState].
  static void moveCall(
    ChatId chatId,
    ChatId newChatId, {
    WebStoredCall? newState,
  }) {
    // No-op.
  }

  /// Removes all calls from the browser's storage, if any.
  static void removeAllCalls() {
    // No-op.
  }

  /// Indicates whether the browser's storage contains a call identified by the
  /// provided [chatId].
  static bool containsCall(ChatId chatId) => false;

  /// Indicates whether the browser's storage contains any calls.
  static bool containsCalls() => false;

  /// Sets the [prefs] as the provided call's popup window preferences.
  static void setCallRect(ChatId chatId, Rect prefs) {
    // No-op.
  }

  /// Returns the [Rect] stored by the provided [chatId], if any.
  static Rect? getCallRect(ChatId chatId) => null;

  /// Downloads the file from the provided [url].
  static Future<void> downloadFile(String url, String name) async {
    // No-op.
  }

  /// Prints a string representation of the provided [object] to the console as
  /// an error.
  static void consoleError(Object? object) {
    // No-op.
  }

  /// Requests the permission to use a camera.
  static Future<void> cameraPermission() async {
    try {
      await Permission.camera.request();
    } catch (_) {
      // No-op.
    }
  }

  /// Requests the permission to use a microphone.
  static Future<void> microphonePermission() async {
    try {
      await Permission.microphone.request();
    } catch (_) {
      // No-op.
    }
  }

  /// Replaces the provided [from] with the specified [to] in the current URL.
  static void replaceState(String from, String to) {
    // No-op.
  }
}

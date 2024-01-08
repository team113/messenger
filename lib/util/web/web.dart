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

// ignore_for_file: avoid_web_libraries_in_flutter

/// Helper providing direct access to browser-only features.
@JS()
library web_utils;

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js';
import 'dart:js_util';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show NotificationResponse, NotificationResponseType;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:uuid/uuid.dart';

import '../platform_utils.dart';
import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/session.dart';
import '/routes.dart';
import 'web_utils.dart';

html.Navigator _navigator = html.window.navigator;

@JS('document.documentElement.requestFullscreen')
external dynamic requestFullscreen();

@JS('document.documentElement.requestFullscreen')
external dynamic requestFullscreenClosure;

@JS('document.documentElement.mozRequestFullScreen')
external dynamic mozRequestFullScreen();

@JS('document.documentElement.mozRequestFullScreen')
external dynamic mozRequestFullScreenClosure;

@JS('document.documentElement.webkitRequestFullScreen')
external dynamic webkitRequestFullScreen();

@JS('document.documentElement.webkitRequestFullScreen')
external dynamic webkitRequestFullScreenClosure;

@JS('document.documentElement.msRequestFullscreen')
external dynamic msRequestFullscreen();

@JS('document.documentElement.msRequestFullscreen')
external dynamic msRequestFullscreenClosure;

@JS('document.exitFullscreen')
external dynamic exitFullscreen();

@JS('document.exitFullscreen')
external dynamic exitFullscreenClosure;

@JS('document.mozCancelFullScreen')
external dynamic mozCancelFullScreen();

@JS('document.mozCancelFullScreen')
external dynamic mozCancelFullScreenClosure;

@JS('document.webkitCancelFullScreen')
external dynamic webkitCancelFullScreen();

@JS('document.webkitCancelFullScreen')
external dynamic webkitCancelFullScreenClosure;

@JS('document.msExitFullscreen')
external dynamic msExitFullscreen();

@JS('document.msExitFullscreen')
external dynamic msExitFullscreenClosure;

@JS('document.fullscreenElement')
external dynamic fullscreenElement;

@JS('document.webkitFullscreenElement')
external dynamic webkitFullscreenElement;

@JS('document.msFullscreenElement')
external dynamic msFullscreenElement;

@JS('cleanIndexedDB')
external cleanIndexedDB();

@JS('window.isPopup')
external bool _isPopup;

@JS('document.hasFocus')
external bool _hasFocus();

@JS('window.mutex.lock')
external Future<void> _lockMutex(String id);

@JS('window.mutex.release')
external Future<void> _releaseMutex(String id);

/// Helper providing access to features having different implementations in
/// browser and on native platforms.
class WebUtils {
  /// Callback, called when user taps on a notification.
  static void Function(NotificationResponse)? onSelectNotification;

  /// Indicates whether device's OS is macOS or iOS.
  static bool get isMacOS =>
      _navigator.appVersion.contains('Mac') && !PlatformUtils.isIOS;

  /// Indicates whether device's browser is Safari or not.
  static bool get isSafari => browser.isSafari;

  /// Indicates whether device's browser is in fullscreen mode or not.
  static bool get isFullscreen {
    return (fullscreenElement != null ||
        webkitFullscreenElement != null ||
        msFullscreenElement != null);
  }

  /// Indicates whether device's browser is in focus.
  static bool get isFocused => _hasFocus();

  /// Returns a stream broadcasting browser's fullscreen changes.
  static Stream<bool> get onFullscreenChange {
    StreamController<bool>? controller;

    // Event listener reacting on fullscreen mode changes.
    void fullscreenListener(html.Event _) => controller!.add(isFullscreen);

    controller = StreamController<bool>(
      onListen: () {
        html.document
            .addEventListener('webkitfullscreenchange', fullscreenListener);
        html.document
            .addEventListener('mozfullscreenchange', fullscreenListener);
        html.document.addEventListener('fullscreenchange', fullscreenListener);
        html.document
            .addEventListener('MSFullscreenChange', fullscreenListener);
      },
      onCancel: () {
        html.document
            .removeEventListener('webkitfullscreenchange', fullscreenListener);
        html.document
            .removeEventListener('mozfullscreenchange', fullscreenListener);
        html.document
            .removeEventListener('fullscreenchange', fullscreenListener);
        html.document
            .removeEventListener('MSFullscreenChange', fullscreenListener);
      },
    );

    return controller.stream;
  }

  /// Returns a stream broadcasting the browser's storage changes.
  static Stream<WebStorageEvent> get onStorageChange {
    StreamController<WebStorageEvent>? controller;

    // Event listener reacting on storage changes.
    void storageListener(html.Event event) {
      event as html.StorageEvent;
      controller!.add(
        WebStorageEvent(
          key: event.key,
          newValue: event.newValue,
          oldValue: event.oldValue,
        ),
      );
    }

    controller = StreamController(
      onListen: () => html.window.addEventListener('storage', storageListener),
      onCancel: () =>
          html.window.removeEventListener('storage', storageListener),
    );

    return controller.stream;
  }

  /// Returns a stream broadcasting the device's browser focus changes.
  static Stream<bool> get onFocusChanged {
    StreamController<bool>? controller;

    // Event listener reacting on window focus events.
    void focusListener(html.Event event) => controller!.add(true);

    // Event listener reacting on window unfocus events.
    void blurListener(html.Event event) => controller!.add(false);

    controller = StreamController(
      onListen: () {
        html.window.addEventListener('focus', focusListener);
        html.window.addEventListener('blur', blurListener);
      },
      onCancel: () {
        html.window.removeEventListener('focus', focusListener);
        html.window.removeEventListener('blur', blurListener);
      },
    );

    return controller.stream;
  }

  /// Returns a stream broadcasting the browser's window focus changes.
  static Stream<bool> get onWindowFocus {
    StreamController<bool>? controller;

    // Event listener reacting on mouse enter events.
    void enterListener(html.Event event) => controller!.add(true);

    // Event listener reacting on mouse leave events.
    void leaveListener(html.Event event) => controller!.add(false);

    controller = StreamController(
      onListen: () {
        html.document.addEventListener('mouseenter', enterListener);
        html.document.addEventListener('mouseleave', leaveListener);
      },
      onCancel: () {
        html.document.removeEventListener('mouseenter', enterListener);
        html.document.removeEventListener('mouseleave', leaveListener);
      },
    );

    return controller.stream;
  }

  /// Returns a stream broadcasting the browser's broadcast channel changes.
  static Stream<dynamic> get onBroadcastMessage {
    StreamController<dynamic>? controller;
    StreamSubscription? subscription;

    final channel = html.BroadcastChannel('fcm');

    controller = StreamController(
      onListen: () {
        subscription = channel.onMessage.listen((e) => controller?.add(e.data));
      },
      onCancel: () => subscription?.cancel(),
    );

    return controller.stream;
  }

  /// Sets the provided [Credentials] to the browser's storage.
  static set credentials(Credentials? creds) {
    if (creds == null) {
      html.window.localStorage.remove('credentials');
    } else {
      html.window.localStorage['credentials'] = json.encode(creds.toJson());
    }
  }

  /// Returns the stored in browser's storage [Credentials].
  static Credentials? get credentials {
    if (html.window.localStorage['credentials'] == null) {
      return null;
    } else {
      var decoded = json.decode(html.window.localStorage['credentials']!);
      return Credentials.fromJson(decoded);
    }
  }

  /// Indicates whether the current window is a popup.
  static bool get isPopup => _isPopup;

  /// Indicates whether [Credentials] are considered being updated currently.
  static Future<bool> get credentialsAreLocked async {
    return await _protect(() {
      final String? updating = html.window.localStorage['credentialsUpdating'];

      if (updating == null) {
        return false;
      } else {
        return updating.toLowerCase() == 'true';
      }
    });
  }

  /// Sets the provided [updating] value to the browser's storage indicating an
  /// ongoing [Credentials] refresh.
  static Future<void> lockCredentials(bool updating) async {
    await _protect(() {
      html.window.localStorage['credentialsUpdating'] = updating.toString();
    });
  }

  /// Pushes [title] to browser's window title.
  static void title(String title) =>
      SystemChrome.setApplicationSwitcherDescription(
          ApplicationSwitcherDescription(label: title));

  /// Sets the URL strategy of your web app to using paths instead of a leading
  /// hash (`#`).
  static void setPathUrlStrategy() {
    if (urlStrategy is! PathUrlStrategy) {
      setUrlStrategy(PathUrlStrategy());
    }
  }

  // TODO: Styles page related, should be removed at some point.
  /// Downloads the file from [url] and saves it as [filename].
  static Future<void> download(String url, String filename) async =>
      await context.callMethod('webSaveAs', [url, filename]);

  /// Toggles browser's fullscreen to [enable], and returns the resulting
  /// fullscreen state.
  ///
  /// Always returns `false` if fullscreen is not supported.
  static bool toggleFullscreen(bool enable) {
    if (html.document.fullscreenEnabled == false) {
      return false;
    }

    if (enable) {
      if (requestFullscreenClosure != null) {
        requestFullscreen();
      } else if (mozRequestFullScreenClosure != null) {
        mozRequestFullScreen();
      } else if (webkitRequestFullScreenClosure != null) {
        webkitRequestFullScreen();
      } else if (msRequestFullscreenClosure != null) {
        msRequestFullscreen();
      }
    } else {
      if (exitFullscreenClosure != null) {
        exitFullscreen();
      } else if (mozCancelFullScreenClosure != null) {
        mozCancelFullScreen();
      } else if (webkitCancelFullScreenClosure != null) {
        webkitCancelFullScreen();
      } else if (msExitFullscreenClosure != null) {
        msExitFullscreen();
      }
    }

    return enable;
  }

  /// Shows a notification via "Notification API" of the browser.
  static Future<void> showNotification(
    String title, {
    String? dir,
    String? body,
    String? lang,
    String? tag,
    String? icon,
  }) async {
    var notification = html.Notification(
      title,
      dir: dir,
      body: body,
      lang: lang,
      tag: tag,
      icon: icon,
    );

    notification.onClick.listen((event) {
      onSelectNotification?.call(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: notification.lang,
      ));
      notification.close();
    });
  }

  /// Clears the browser's `IndexedDB`.
  static Future<void> cleanIndexedDb() async {
    try {
      await promiseToFuture(cleanIndexedDB());
    } catch (e) {
      consoleError(e);
    }
  }

  /// Clears the browser's storage.
  static void cleanStorage() => html.window.localStorage.clear();

  /// Opens a new popup window at the [Routes.call] page with the provided
  /// [chatId].
  static bool openPopupCall(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = false,
    bool withScreen = false,
  }) {
    final screenW = html.window.screen?.width ?? 500;
    final screenH = html.window.screen?.height ?? 500;

    final Rect? prefs = getCallRect(chatId);

    final width = min(prefs?.width ?? 500, screenW);
    final height = min(prefs?.height ?? 500, screenH);

    var left = prefs?.left ?? screenW - 50 - width;
    if (left < 0) {
      left = 0;
    } else if (left + width > screenW) {
      left = screenW - width;
    }

    var top = prefs?.top ?? 50;
    if (top < 0) {
      top = 0;
    } else if (top + height > screenH) {
      top = screenH.toDouble() - height;
    }

    List parameters = [
      if (withAudio != true) 'audio=$withAudio',
      if (withVideo != false) 'video=$withVideo',
      if (withScreen != false) 'screen=$withScreen',
    ];

    var query = parameters.isEmpty ? '' : '?${parameters.join('&')}';

    var window = html.window.open(
      '${Routes.call}/$chatId$query',
      'call_${const Uuid().v4()}',
      'popup=1,width=$width,height=$height,left=$left,top=$top',
    );

    try {
      return window.closed != true;
    } catch (_) {
      return false;
    }
  }

  /// Closes the current window.
  static void closeWindow() => html.window.close();

  /// Returns a call identified by the provided [chatId] from the browser's
  /// storage.
  static WebStoredCall? getCall(ChatId chatId) {
    var data = html.window.localStorage['call_$chatId'];
    if (data != null) {
      return WebStoredCall.fromJson(json.decode(data));
    }

    return null;
  }

  /// Stores the provided [call] in the browser's storage.
  static void setCall(WebStoredCall call) =>
      html.window.localStorage['call_${call.chatId}'] =
          json.encode(call.toJson());

  /// Removes a call identified by the provided [chatId] from the browser's
  /// storage.
  static void removeCall(ChatId chatId) =>
      html.window.localStorage.remove('call_$chatId');

  /// Moves a call identified by its [chatId] to the [newChatId] replacing its
  /// stored state with an optional [newState].
  static void moveCall(
    ChatId chatId,
    ChatId newChatId, {
    WebStoredCall? newState,
  }) {
    newState ??= WebUtils.getCall(chatId);
    WebUtils.removeCall(chatId);
    WebUtils.setCall(newState!);
    replaceState(chatId.val, newChatId.val);
  }

  /// Removes all calls from the browser's storage, if any.
  static void removeAllCalls() {
    for (var k in html.window.localStorage.keys) {
      if (k.startsWith('call_')) {
        html.window.localStorage.remove(k);
      }
    }
  }

  /// Indicates whether the browser's storage contains a call identified by the
  /// provided [chatId].
  static bool containsCall(ChatId chatId) =>
      html.window.localStorage.containsKey('call_$chatId');

  /// Indicates whether the browser's storage contains any calls.
  static bool containsCalls() {
    for (var e in html.window.localStorage.entries) {
      if (e.key.startsWith('call_')) {
        return true;
      }
    }

    return false;
  }

  /// Sets the [prefs] as the provided call's popup window preferences.
  static void setCallRect(ChatId chatId, Rect prefs) =>
      html.window.localStorage['prefs_call_$chatId'] =
          json.encode(prefs.toJson());

  /// Returns the [Rect] stored by the provided [chatId], if any.
  static Rect? getCallRect(ChatId chatId) {
    var data = html.window.localStorage['prefs_call_$chatId'];
    if (data != null) {
      return _RectExtension.fromJson(json.decode(data));
    }

    return null;
  }

  /// Downloads a file from the provided [url].
  static Future<void> downloadFile(String url, String name) async {
    final Response response = await (await PlatformUtils.dio).head(url);
    if (response.statusCode != 200) {
      throw Exception('Cannot download file');
    }

    final html.AnchorElement anchorElement = html.AnchorElement(href: url);
    anchorElement.download = name;
    anchorElement.click();
  }

  /// Prints a string representation of the provided [object] to the console as
  /// an error.
  static void consoleError(Object? object) => html.window.console.error(object);

  /// Requests the permission to use a camera.
  static Future<void> cameraPermission() async {
    final status =
        await html.window.navigator.permissions?.query({'name': 'camera'});

    if (status?.state != 'granted') {
      final html.MediaStream? stream = await html.window.navigator.mediaDevices
          ?.getUserMedia({'video': true});

      if (stream == null) {
        throw UnsupportedError('`window.navigator.mediaDevices` are `null`');
      }

      for (var e in stream.getTracks()) {
        e.stop();
      }
    }
  }

  /// Requests the permission to use a microphone.
  static Future<void> microphonePermission() async {
    final status =
        await html.window.navigator.permissions?.query({'name': 'microphone'});

    if (status?.state != 'granted') {
      final html.MediaStream? stream = await html.window.navigator.mediaDevices
          ?.getUserMedia({'audio': true});

      if (stream == null) {
        throw UnsupportedError('`window.navigator.mediaDevices` are `null`');
      }

      for (var e in stream.getTracks()) {
        e.stop();
      }
    }
  }

  /// Replaces the provided [from] with the specified [to] in the current URL.
  static void replaceState(String from, String to) {
    html.window.history.replaceState(
      null,
      html.document.title,
      Uri.base.toString().replaceFirst(from, to),
    );
  }

  /// Sets the favicon being used to an alert style.
  static void setAlertFavicon() {
    for (html.LinkElement e in html.querySelectorAll("link[rel*='icon']")) {
      if (!e.href.contains('icons/alert/')) {
        e.href = e.href.replaceFirst('icons/', 'icons/alert/');
      }
    }
  }

  /// Sets the favicon being used to the default style.
  static void setDefaultFavicon() {
    for (html.LinkElement e in html.querySelectorAll("link[rel*='icon']")) {
      e.href = e.href.replaceFirst('icons/alert/', 'icons/');
    }
  }

  /// Sets callback to be fired whenever Rust code panics.
  static void onPanic(void Function(String)? cb) {
    // No-op.
  }

  /// Deletes the loader element.
  static void deleteLoader() {
    html.document.getElementById('loader')?.remove();
  }

  /// Returns the `User-Agent` header to put in the network queries.
  static Future<String> get userAgent async {
    final info = await DeviceInfoPlugin().webBrowserInfo;
    return info.userAgent ??
        '${Config.userAgentProduct}/${Config.userAgentVersion}';
  }

  static Future<void> play(String asset) async {
    final e = html.document.getElementById(asset);
    print('[WebUtils] play $asset');

    if (e is html.AudioElement) {
      e.muted = false;
      await e.play();
    }
  }

  static void stop(String asset) {
    final e = html.document.getElementById(asset);
    if (e is html.AudioElement) {
      e.currentTime = 0;
      e.pause();
    }
  }

  /// Guards the [function] with the browser's storage mutex.
  static Future<T> _protect<T>(FutureOr<T> Function() function) async {
    try {
      await _lockMutex('mutex');
    } catch (_) {
      // No-op, if failed to acquire by timeout.
    }

    try {
      return await function();
    } finally {
      try {
        await _releaseMutex('mutex');
      } catch (_) {
        // No-op, if failed to release by timeout.
      }
    }
  }
}

/// Extension adding JSON manipulation methods to a [Rect].
extension _RectExtension on Rect {
  /// Returns a [Map] containing parameters of this [Rect].
  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'left': left,
        'top': top,
      };

  /// Constructs a [Rect] from the provided [data].
  static Rect fromJson(Map<dynamic, dynamic> data) => Rect.fromLTWH(
        data['left'],
        data['top'],
        data['width'],
        data['height'],
      );
}

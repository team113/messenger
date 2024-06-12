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
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:js_util';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show NotificationResponse, NotificationResponseType;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:mutex/mutex.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;

import '../log.dart';
import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/routes.dart';
import '/util/platform_utils.dart';
import 'web_utils.dart';

web.Navigator _navigator = web.window.navigator;

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
external cleanIndexedDB(dynamic);

@JS('window.isPopup')
external bool _isPopup;

@JS('document.hasFocus')
external bool _hasFocus();

@JS('navigator.locks.request')
external Future<dynamic> _requestLock(
  String resource,
  dynamic Function(dynamic) callback,
);

@JS('getLocks')
external Future<dynamic> _getLocks();

@JS('locksAvailable')
external bool _locksAvailable();

/// Helper providing access to features having different implementations in
/// browser and on native platforms.
class WebUtils {
  /// Callback, called when user taps on a notification.
  static void Function(NotificationResponse)? onSelectNotification;

  /// [Mutex]es guarding the [protect] method.
  static final Map<String, Mutex> _guards = {};

  /// Indicator whether [cameraPermission] has finished successfully.
  ///
  /// Only populated and used, if [isFirefox] is `true`.
  static bool _hasCameraPermission = false;

  /// Indicator whether [microphonePermission] has finished successfully.
  ///
  /// Only populated and used, if [isFirefox] is `true`.
  static bool _hasMicrophonePermission = false;

  /// Indicates whether device's OS is macOS or iOS.
  static bool get isMacOS =>
      _navigator.appVersion.contains('Mac') && !PlatformUtils.isIOS;

  /// Indicates whether device's browser is Safari or not.
  static bool get isSafari => browser.isSafari;

  /// Indicates whether device's browser is Firefox or not.
  static bool get isFirefox => browser.isFirefox;

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
    void fullscreenListener(web.Event _) => controller!.add(isFullscreen);

    controller = StreamController<bool>(
      onListen: () {
        web.document.addEventListener(
          'webkitfullscreenchange',
          fullscreenListener.toJS,
        );
        web.document
            .addEventListener('mozfullscreenchange', fullscreenListener.toJS);
        web.document
            .addEventListener('fullscreenchange', fullscreenListener.toJS);
        web.document
            .addEventListener('MSFullscreenChange', fullscreenListener.toJS);
      },
      onCancel: () {
        web.document.removeEventListener(
          'webkitfullscreenchange',
          fullscreenListener.toJS,
        );
        web.document.removeEventListener(
          'mozfullscreenchange',
          fullscreenListener.toJS,
        );
        web.document
            .removeEventListener('fullscreenchange', fullscreenListener.toJS);
        web.document
            .removeEventListener('MSFullscreenChange', fullscreenListener.toJS);
      },
    );

    return controller.stream;
  }

  /// Returns a stream broadcasting the browser's storage changes.
  static Stream<WebStorageEvent> get onStorageChange {
    StreamController<WebStorageEvent>? controller;

    // Event listener reacting on storage changes.
    void storageListener(web.Event event) {
      event as web.StorageEvent;
      controller!.add(
        WebStorageEvent(
          key: event.key,
          newValue: event.newValue,
          oldValue: event.oldValue,
        ),
      );
    }

    controller = StreamController(
      onListen: () =>
          web.window.addEventListener('storage', storageListener.toJS),
      onCancel: () =>
          web.window.removeEventListener('storage', storageListener.toJS),
    );

    return controller.stream;
  }

  /// Returns a stream broadcasting the device's browser focus changes.
  static Stream<bool> get onFocusChanged {
    StreamController<bool>? controller;

    // Event listener reacting on window focus events.
    void focusListener(web.Event event) => controller!.add(true);

    // Event listener reacting on window unfocus events.
    void blurListener(web.Event event) => controller!.add(false);

    controller = StreamController(
      onListen: () {
        web.window.addEventListener('focus', focusListener.toJS);
        web.window.addEventListener('blur', blurListener.toJS);
      },
      onCancel: () {
        web.window.removeEventListener('focus', focusListener.toJS);
        web.window.removeEventListener('blur', blurListener.toJS);
      },
    );

    return controller.stream;
  }

  /// Returns a stream broadcasting the browser's window focus changes.
  static Stream<bool> get onWindowFocus {
    StreamController<bool>? controller;

    // Event listener reacting on mouse enter events.
    void enterListener(web.Event event) => controller!.add(true);

    // Event listener reacting on mouse leave events.
    void leaveListener(web.Event event) => controller!.add(false);

    controller = StreamController(
      onListen: () {
        web.document.addEventListener('mouseenter', enterListener.toJS);
        web.document.addEventListener('mouseleave', leaveListener.toJS);
      },
      onCancel: () {
        web.document.removeEventListener('mouseenter', enterListener.toJS);
        web.document.removeEventListener('mouseleave', leaveListener.toJS);
      },
    );

    return controller.stream;
  }

  /// Returns a stream broadcasting the browser's broadcast channel changes.
  static Stream<dynamic> get onBroadcastMessage {
    StreamController<dynamic>? controller;

    final channel = web.BroadcastChannel('fcm');

    controller = StreamController(
      onListen: () {
        void fn(web.Event e) => controller?.add(e.getProperty('data'.toJS));
        channel.onmessage = fn.toJS;
      },
      onCancel: () => channel.onmessage = null,
    );

    return controller.stream;
  }

  /// Indicates whether the current window is a popup.
  static bool get isPopup => _isPopup;

  /// Indicates whether the [protect] is currently locked.
  static FutureOr<bool> get isLocked async {
    // Web Locks API is unavailable for some reason, so proceed without it.
    if (!_locksAvailable()) {
      return false;
    }

    bool held = false;

    try {
      final locks = await promiseToFuture(_getLocks());
      held = (locks as List?)?.any((e) => e.name == 'mutex') == true;
    } catch (e) {
      held = false;
    }

    return _guards['mutex']?.isLocked == true || held;
  }

  /// Removes [Credentials] identified by the provided [UserId] from the
  /// browser's storage.
  static void removeCredentials(UserId userId) {
    web.window.localStorage.removeItem('credentials_$userId');
  }

  /// Puts the provided [Credentials] to the browser's storage.
  static void putCredentials(Credentials creds) {
    web.window.localStorage['credentials_${creds.userId}'] = json.encode(
      creds.toJson(),
    );
  }

  /// Returns the stored in browser's storage [Credentials] identified by the
  /// provided [UserId], if any.
  static Credentials? getCredentials(UserId userId) {
    if (web.window.localStorage['credentials_$userId'] == null) {
      return null;
    } else {
      return Credentials.fromJson(
        json.decode(web.window.localStorage['credentials_$userId']!),
      );
    }
  }

  /// Guarantees the [callback] is invoked synchronously, only by single tab or
  /// code block at the same time.
  static Future<T> protect<T>(
    Future<T> Function() callback, {
    String tag = 'mutex',
  }) async {
    Mutex? mutex = _guards[tag];
    if (mutex == null) {
      mutex = Mutex();
      _guards[tag] = mutex;
    }

    return await mutex.protect(() async {
      // Web Locks API is unavailable for some reason, so proceed without it.
      if (!_locksAvailable()) {
        return await callback();
      }

      final Completer<T> completer = Completer();

      try {
        await promiseToFuture(
          _requestLock(
            tag,
            allowInterop(
              (_) => callback()
                  .then((T val) => completer.complete(val))
                  .onError(
                    (e, stackTrace) => completer.completeError(
                      e ?? Exception(),
                      stackTrace,
                    ),
                  )
                  .toJS,
            ),
          ),
        );
      } catch (_) {
        // If completer is completed, then the exception is already handled.
        if (!completer.isCompleted) {
          rethrow;
        }
      }

      return await completer.future;
    });
  }

  /// Pushes [title] to browser's window title.
  static void title(String title) =>
      SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(label: title),
      );

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
      await callMethod(web.document, 'webSaveAs', [url, filename]);

  /// Toggles browser's fullscreen to [enable], and returns the resulting
  /// fullscreen state.
  ///
  /// Always returns `false` if fullscreen is not supported.
  static bool toggleFullscreen(bool enable) {
    try {
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
    } catch (e) {
      Log.debug('Can\'t toggle fullscreen: $e', 'WebUtils');
      return false;
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
    final notification = web.Notification(
      title,
      web.NotificationOptions(
        dir: dir ?? '123',
        body: body ?? '123',
        lang: lang ?? '123',
        tag: tag ?? '123',
        icon: icon ?? '123',
        silent: false,
      ),
    );

    void fn(web.Event _) {
      onSelectNotification?.call(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: notification.lang,
      ));
      notification.close();
    }

    notification.onclick = fn.toJS;
  }

  /// Clears the browser's `IndexedDB`.
  static Future<void> cleanIndexedDb({String? except}) async {
    try {
      await promiseToFuture(cleanIndexedDB(except));
    } catch (e) {
      consoleError(e);
    }
  }

  /// Clears the browser's storage.
  static void cleanStorage() => web.window.localStorage.clear();

  /// Opens a new popup window at the [Routes.call] page with the provided
  /// [chatId].
  static bool openPopupCall(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = false,
    bool withScreen = false,
  }) {
    final int screenW = web.window.screen.width;
    final int screenH = web.window.screen.height;

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

    final List<String> parameters = [
      if (withAudio != true) 'audio=$withAudio',
      if (withVideo != false) 'video=$withVideo',
      if (withScreen != false) 'screen=$withScreen',
    ];

    final String query = parameters.isEmpty ? '' : '?${parameters.join('&')}';

    final web.Window? window = web.window.open(
      '${Routes.call}/$chatId$query',
      'call_${const Uuid().v4()}',
      'popup=1,width=$width,height=$height,left=$left,top=$top',
    );

    try {
      return window?.closed != true;
    } catch (_) {
      return false;
    }
  }

  /// Closes the current window.
  static void closeWindow() => web.window.close();

  /// Returns a call identified by the provided [chatId] from the browser's
  /// storage.
  static WebStoredCall? getCall(ChatId chatId) {
    var data = web.window.localStorage['call_$chatId'];
    if (data != null) {
      return WebStoredCall.fromJson(json.decode(data));
    }

    return null;
  }

  /// Stores the provided [call] in the browser's storage.
  static void setCall(WebStoredCall call) =>
      web.window.localStorage['call_${call.chatId}'] =
          json.encode(call.toJson());

  /// Removes a call identified by the provided [chatId] from the browser's
  /// storage.
  static void removeCall(ChatId chatId) =>
      web.window.localStorage.removeItem('call_$chatId');

  /// Moves a call identified by its [chatId] to the [newChatId] replacing its
  /// stored state with an optional [newState].
  static void moveCall(
    ChatId chatId,
    ChatId newChatId, {
    WebStoredCall? newState,
  }) {
    newState ??= getCall(chatId);
    removeCall(chatId);
    setCall(newState!);
    replaceState(chatId.val, newChatId.val);
  }

  /// Removes all calls from the browser's storage, if any.
  static void removeAllCalls() {
    for (var i = 0; i < web.window.localStorage.length; ++i) {
      final k = web.window.localStorage.key(i);
      if (k?.startsWith('call_') ?? false) {
        web.window.localStorage.removeItem(k!);
      }
    }
  }

  /// Indicates whether the browser's storage contains a call identified by the
  /// provided [chatId].
  static bool containsCall(ChatId chatId) =>
      web.window.localStorage.getItem('call_$chatId') != null;

  /// Indicates whether the browser's storage contains any calls.
  static bool containsCalls() {
    for (var i = 0; i < web.window.localStorage.length; ++i) {
      final k = web.window.localStorage.key(i);
      if (k?.startsWith('call_') ?? false) {
        return true;
      }
    }

    return false;
  }

  /// Sets the [prefs] as the provided call's popup window preferences.
  static void setCallRect(ChatId chatId, Rect prefs) =>
      web.window.localStorage['prefs_call_$chatId'] =
          json.encode(prefs.toJson());

  /// Returns the [Rect] stored by the provided [chatId], if any.
  static Rect? getCallRect(ChatId chatId) {
    var data = web.window.localStorage['prefs_call_$chatId'];
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

    final web.HTMLAnchorElement anchorElement = web.HTMLAnchorElement()
      ..href = url;
    anchorElement.download = name;
    anchorElement.click();
  }

  /// Prints a string representation of the provided [object] to the console as
  /// an error.
  static void consoleError(Object? object) =>
      web.console.error(object?.toString().toJS);

  /// Requests the permission to use a camera.
  static Future<void> cameraPermission() async {
    bool granted = _hasCameraPermission;

    // Firefox doesn't allow to check whether app has camera permission:
    // https://searchfox.org/mozilla-central/source/dom/webidl/Permissions.webidl#10
    if (!isFirefox) {
      final permission = await web.window.navigator.permissions
          .query({'name': 'camera'}.toJSBox)
          .toDart;
      granted = permission.state == 'granted';
    }

    if (!granted) {
      final web.MediaStream stream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(video: true.toJS))
          .toDart;

      if (isFirefox) {
        _hasCameraPermission = true;
      }

      for (var e in stream.getTracks().toDart) {
        e.stop();
      }
    }
  }

  /// Requests the permission to use a microphone.
  static Future<void> microphonePermission() async {
    bool granted = _hasMicrophonePermission;

    // Firefox doesn't allow to check whether app has microphone permission:
    // https://searchfox.org/mozilla-central/source/dom/webidl/Permissions.webidl#10
    if (!isFirefox) {
      final permission = await web.window.navigator.permissions
          .query({'name': 'microphone'}.toJSBox)
          .toDart;
      granted = permission.state == 'granted';
    }

    if (!granted) {
      final web.MediaStream stream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
          .toDart;

      if (isFirefox) {
        _hasMicrophonePermission = true;
      }

      for (var e in stream.getTracks().toDart) {
        e.stop();
      }
    }
  }

  /// Replaces the provided [from] with the specified [to] in the current URL.
  static void replaceState(String from, String to) {
    router.replace(from, to);
    web.window.history.replaceState(
      null,
      web.document.title,
      Uri.base.toString().replaceFirst(from, to),
    );
  }

  /// Sets the favicon being used to an alert style.
  static void setAlertFavicon() {
    final nodes = web.document.querySelectorAll("link[rel*='icon']");
    for (int i = 0; i < nodes.length; ++i) {
      final web.Node? e = nodes.item(i);

      if (e != null) {
        e.setProperty(
          'href'.toJS,
          (e.getProperty('href'.toJS) as String)
              .replaceFirst('icons/', 'icons/alert/')
              .toJS,
        );
      }
    }
  }

  /// Sets the favicon being used to the default style.
  static void setDefaultFavicon() {
    final nodes = web.document.querySelectorAll("link[rel*='icon']");
    for (int i = 0; i < nodes.length; ++i) {
      final web.Node? e = nodes.item(i);

      if (e != null) {
        e.setProperty(
          'href'.toJS,
          (e.getProperty('href'.toJS) as String)
              .replaceFirst('icons/alert/', 'icons/')
              .toJS,
        );
      }
    }
  }

  /// Sets callback to be fired whenever Rust code panics.
  static void onPanic(void Function(String)? cb) {
    // No-op.
  }

  /// Deletes the loader element.
  static void deleteLoader() {
    web.document.getElementById('loader')?.remove();
  }

  /// Registers the custom [Config.scheme].
  static Future<void> registerScheme() async {
    // No-op.
  }

  /// Returns the `User-Agent` header to put in the network queries.
  static Future<String> get userAgent async {
    final info = await DeviceInfoPlugin().webBrowserInfo;
    return info.userAgent ??
        '${Config.userAgentProduct}/${Config.userAgentVersion}';
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

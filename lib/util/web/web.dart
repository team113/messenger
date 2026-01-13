// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show NotificationResponse;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:http/http.dart' show Client;
import 'package:platform_detect/platform_detect.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player_web/video_player_web.dart';
import 'package:web/web.dart' as web;

import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/routes.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';
import 'web_utils.dart';

web.Navigator _navigator = web.window.navigator;

@JS('document.documentElement.requestFullscreen')
external void requestFullscreen();

@JS('document.documentElement.requestFullscreen')
external JSFunction? requestFullscreenClosure;

@JS('document.documentElement.mozRequestFullScreen')
external void mozRequestFullScreen();

@JS('document.documentElement.mozRequestFullScreen')
external JSFunction? mozRequestFullScreenClosure;

@JS('document.documentElement.webkitRequestFullScreen')
external void webkitRequestFullScreen();

@JS('document.documentElement.webkitRequestFullScreen')
external JSFunction? webkitRequestFullScreenClosure;

@JS('document.documentElement.msRequestFullscreen')
external void msRequestFullscreen();

@JS('document.documentElement.msRequestFullscreen')
external JSFunction? msRequestFullscreenClosure;

@JS('document.exitFullscreen')
external void exitFullscreen();

@JS('document.exitFullscreen')
external JSFunction? exitFullscreenClosure;

@JS('document.mozCancelFullScreen')
external void mozCancelFullScreen();

@JS('document.mozCancelFullScreen')
external JSFunction? mozCancelFullScreenClosure;

@JS('document.webkitCancelFullScreen')
external void webkitCancelFullScreen();

@JS('document.webkitCancelFullScreen')
external JSFunction? webkitCancelFullScreenClosure;

@JS('document.msExitFullscreen')
external void msExitFullscreen();

@JS('document.msExitFullscreen')
external JSFunction? msExitFullscreenClosure;

@JS('document.fullscreenElement')
external JSAny? fullscreenElement;

@JS('document.webkitFullscreenElement')
external JSAny? webkitFullscreenElement;

@JS('document.msFullscreenElement')
external JSAny? msFullscreenElement;

@JS('cleanIndexedDB')
external JSPromise<JSAny?> cleanIndexedDB(String? except);

@JS('navigator.setAppBadge')
external void setAppBadge(int count);

@JS('navigator.clearAppBadge')
external void clearAppBadge();

@JS('navigator.setAppBadge')
external JSFunction? setAppBadgeClosure;

@JS('window.isPopup')
external bool _isPopup;

@JS('document.hasFocus')
external bool _hasFocus();

@JS('navigator.locks.request')
external JSPromise<JSAny?> _requestLock(
  String resource,
  JSObject options,
  JSExportedDartFunction callback,
);

@JS('getLocks')
external JSPromise<JSAny?> _getLocks();

@JS('locksAvailable')
external bool _locksAvailable();

@JS('webSaveAs')
external JSPromise<JSAny?> _webSaveAs(web.Blob blob, JSString name);

@JS('audioContext')
web.AudioContext? _context;

/// Helper providing access to features having different implementations in
/// browser and on native platforms.
class WebUtils {
  /// Callback, called when user taps on a notification.
  static void Function(NotificationResponse)? onSelectNotification;

  /// Indicator whether this device has a PWA installed.
  static bool hasPwa = false;

  /// [Lock]es guarding the [protect] method.
  static final Map<String, Lock> _guards = {};

  /// Handlers for [HotKey]s intended to be manipulated via [bindKey] and
  /// [unbindKey] to invoke [_handleBindKeys].
  static final Map<HotKey, List<bool Function()>> _keyHandlers = {};

  /// Indicates whether device's OS is macOS or iOS.
  static bool get isMacOS =>
      _navigator.appVersion.contains('Mac') && !PlatformUtils.isIOS;

  /// Indicates whether device's browser is Safari or not.
  static bool get isSafari => browser.isSafari;

  /// Indicates whether device's browser is Firefox or not.
  static bool get isFirefox => browser.isFirefox;

  /// Indicates whether device's browser is Chrome or not.
  static bool get isChrome => browser.isChrome;

  /// Indicates whether device's browser is in fullscreen mode or not.
  static bool get isFullscreen {
    return (fullscreenElement != null ||
        webkitFullscreenElement != null ||
        msFullscreenElement != null);
  }

  /// Indicates whether device's browser is in focus.
  static bool get isFocused => _hasFocus();

  /// Indicates whether this device is considered to be running as a PWA.
  static bool get isPwa =>
      web.window.matchMedia('(display-mode: standalone)').matches;

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
        web.document.addEventListener(
          'mozfullscreenchange',
          fullscreenListener.toJS,
        );
        web.document.addEventListener(
          'fullscreenchange',
          fullscreenListener.toJS,
        );
        web.document.addEventListener(
          'MSFullscreenChange',
          fullscreenListener.toJS,
        );
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
        web.document.removeEventListener(
          'fullscreenchange',
          fullscreenListener.toJS,
        );
        web.document.removeEventListener(
          'MSFullscreenChange',
          fullscreenListener.toJS,
        );
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

  /// Returns a stream broadcasting the browser's `fcm` broadcast channel
  /// changes.
  static Stream<dynamic> onBroadcastMessage({String name = 'fcm'}) {
    StreamController<dynamic>? controller;

    final web.BroadcastChannel channel = web.BroadcastChannel(name);

    controller = StreamController(
      onListen: () {
        void fn(web.Event e) =>
            controller?.add((e as web.MessageEvent).data.dartify());
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
      final locks = (await _getLocks().toDart) as JSArray;
      held =
          locks.toDart
              .map((e) => e?.dartify() as Map?)
              .any((e) => e?['name'] == 'mutex') ==
          true;
    } catch (e) {
      held = false;
    }

    return _guards['mutex']?.locked == true || held;
  }

  /// Returns custom [Client] to use for HTTP requests.
  static Client? get httpClient {
    return null;
  }

  /// Indicates whether browser is considering to have connectivity status.
  static bool get isOnLine =>
      web.window.navigator.onLine &&
      (Config.allowDetachedActivity ||
          router.lifecycle.value != AppLifecycleState.detached);

  /// Indicates whether this platform supports system audio capture.
  static FutureOr<bool> get canShareAudio {
    return false;
  }

  /// Removes [Credentials] identified by the provided [UserId] from the
  /// browser's storage.
  static void removeCredentials(UserId userId) {
    web.window.localStorage.removeItem('credentials_$userId');
  }

  /// Puts the provided [Credentials] to the browser's storage.
  static void putCredentials(Credentials creds) {
    web.window.localStorage.setItem(
      'credentials_${creds.userId}',
      json.encode(creds.toJson()),
    );
  }

  /// Returns the stored in browser's storage [Credentials] identified by the
  /// provided [UserId], if any.
  static Credentials? getCredentials(UserId userId) {
    if (web.window.localStorage.getItem('credentials_$userId') == null) {
      return null;
    } else {
      return Credentials.fromJson(
        json.decode(web.window.localStorage.getItem('credentials_$userId')!),
      );
    }
  }

  /// Guarantees the [callback] is invoked synchronously, only by single tab or
  /// code block at the same time.
  static Future<T> protect<T>(
    Future<T> Function() callback, {
    bool exclusive = true,
    String tag = 'mutex',
  }) async {
    Lock? mutex = exclusive ? _guards[tag] : Lock();
    if (mutex == null) {
      mutex = Lock();
      _guards[tag] = mutex;
    }

    return await mutex.synchronized(() async {
      // Web Locks API is unavailable for some reason, so proceed without it.
      if (!_locksAvailable()) {
        return await callback();
      }

      final Completer<T> completer = Completer();

      JSPromise function(JSAny? any) {
        return callback()
            .then((val) => completer.complete(val))
            .onError(
              (e, stackTrace) =>
                  completer.completeError(e ?? Exception(), stackTrace),
            )
            .toJS;
      }

      try {
        await _requestLock(
          tag,
          {'mode': exclusive ? 'exclusive' : 'shared'}.jsify() as JSObject,
          function.toJS,
        ).toDart;
      } catch (e) {
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
    Map<String, dynamic> data = const {},
    List<WebNotificationAction> actions = const [],
  }) async {
    final options = web.NotificationOptions();

    if (dir != null) {
      options.dir = dir;
    }
    if (body != null) {
      options.body = body;
    }
    if (lang != null) {
      options.lang = lang;
    }
    if (tag != null) {
      options.tag = tag;
    }
    if (icon != null) {
      options.icon = icon;
    }
    if (data.isNotEmpty) {
      options.data = data.jsify();
    }

    if (actions.isNotEmpty) {
      options.actions = actions
          .map(
            (e) => web.NotificationAction(
              action: e.id,
              title: e.title,
              icon: e.icon ?? '',
            ),
          )
          .toList()
          .toJS;
    }

    // TODO: `onSelectNotification` was used in `onclick` event in
    //       `Notification` body, however since now notifications are created
    //       by `ServiceWorker`, we have no control over it, so should implement
    //       a way to handle the click in `ServiceWorker`.
    final web.ServiceWorkerRegistration registration =
        await web.window.navigator.serviceWorker.ready.toDart;

    await registration.showNotification(title, options).toDart;
  }

  /// Clears notifications identified by the provided [ChatId] via registered
  /// `ServiceWorker`s.
  static Future<void> clearNotifications(ChatId chatId) async {
    // Try to `postMessage` to active registrations, if any.
    try {
      final List<web.ServiceWorkerRegistration> registrations = await web
          .window
          .navigator
          .serviceWorker
          .getRegistrations()
          .toDart
          .then((js) => js.toDart);

      for (var registration in registrations) {
        registration.active?.postMessage('closeAll:$chatId'.toJS);
      }
    } catch (e) {
      // Ignore errors; SW might not be available yet.
      Log.debug(
        '`clearNotifications($chatId)` has failed due to: $e',
        'WebUtils',
      );
    }
  }

  /// Clears the browser's `IndexedDB`.
  static Future<void> cleanIndexedDb({String? except}) async {
    try {
      await cleanIndexedDB(except).toDart;
    } catch (e) {
      consoleError(e);
    }
  }

  /// Clears the browser's storage.
  static void cleanStorage() => web.window.localStorage.clear();

  /// Opens a new popup window at the [Routes.gallery] page with the provided
  /// [chatId].
  static bool openPopupGallery(ChatId chatId, {String? id, int? index}) {
    Log.debug('openPopupGallery($chatId, id: $id, index: $index)', 'WebUtils');

    final int screenW = web.window.screen.width;
    final int screenH = web.window.screen.height;

    final Rect? prefs = getGalleryRect();

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
      if (id != null) 'id=$id',
      if (index != null) 'index=$index',
    ];

    final String query = parameters.isEmpty ? '' : '?${parameters.join('&')}';

    final web.Window? window = web.window.open(
      '${Routes.gallery}/$chatId$query',
      'gallery_${const Uuid().v4()}',
      'popup=1,width=$width,height=$height,left=$left,top=$top',
    );

    try {
      final bool opened = window?.closed == false;
      Log.debug('openPopupGallery($chatId) -> $opened, $window', 'WebUtils');
      return opened;
    } catch (e) {
      Log.debug('openPopupGallery($chatId) -> failed due to $e', 'WebUtils');
      return false;
    }
  }

  /// Opens a new popup window at the [Routes.call] page with the provided
  /// [chatId].
  static bool openPopupCall(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = false,
    bool withScreen = false,
  }) {
    Log.debug(
      'openPopupCall($chatId, withAudio: $withAudio, withVideo: $withVideo, withScreen: $withScreen)',
      'WebUtils',
    );

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
      final bool opened = window?.closed == false;
      Log.debug('openPopupCall($chatId) -> $opened, $window', 'WebUtils');
      return opened;
    } catch (e) {
      Log.debug('openPopupCall($chatId) -> failed due to $e', 'WebUtils');
      return false;
    }
  }

  /// Closes the current window.
  static void closeWindow() => web.window.close();

  /// Returns a call identified by the provided [chatId] from the browser's
  /// storage.
  static WebStoredCall? getCall(ChatId chatId) {
    final data = web.window.localStorage.getItem('call_$chatId');
    if (data != null) {
      final at = web.window.localStorage.getItem('at_call_$chatId');
      final updatedAt = at == null ? DateTime.now() : DateTime.parse(at);
      if (DateTime.now().difference(updatedAt).inSeconds <= 1) {
        return WebStoredCall.fromJson(json.decode(data));
      }
    }

    return null;
  }

  /// Stores the provided [call] in the browser's storage.
  static void setCall(WebStoredCall call) {
    web.window.localStorage.setItem(
      'call_${call.chatId}',
      json.encode(call.toJson()),
    );

    web.window.localStorage.setItem(
      'at_call_${call.chatId}',
      DateTime.now().add(const Duration(seconds: 5)).toString(),
    );
  }

  /// Ensures a call in the provided [chatId] is considered active the browser's
  /// storage.
  static void pingCall(ChatId chatId) {
    web.window.localStorage.setItem(
      'at_call_$chatId',
      DateTime.now().toString(),
    );
  }

  /// Removes a call identified by the provided [chatId] from the browser's
  /// storage.
  static void removeCall(ChatId chatId) {
    web.window.localStorage.removeItem('call_$chatId');
    web.window.localStorage.removeItem('at_call_$chatId');
  }

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
  static bool containsCall(ChatId chatId) => getCall(chatId) != null;

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
  static void setCallRect(ChatId chatId, Rect prefs) => web.window.localStorage
      .setItem('prefs_call_$chatId', json.encode(prefs.toJson()));

  /// Returns the [Rect] stored by the provided [chatId], if any.
  static Rect? getCallRect(ChatId chatId) {
    final data = web.window.localStorage.getItem('prefs_call_$chatId');
    if (data != null) {
      return _RectExtension.fromJson(json.decode(data));
    }

    return null;
  }

  /// Returns the [Rect] stored for a [openPopupGallery].
  static Rect? getGalleryRect() {
    final data = web.window.localStorage.getItem('gallery_rect');
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

  /// Requests the permission to use a camera and holds it until unsubscribed.
  static Future<StreamSubscription<void>> cameraPermission() async {
    bool granted = false;

    // Firefox doesn't allow to check whether app has camera permission:
    // https://searchfox.org/mozilla-central/source/dom/webidl/Permissions.webidl#10
    if (!isFirefox) {
      final permission = await web.window.navigator.permissions
          .query({'name': 'camera'}.jsify() as JSObject)
          .toDart;
      granted = permission.state == 'granted';
    }

    if (!granted) {
      final web.MediaStream stream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(video: true.toJS))
          .toDart;

      if (isFirefox) {
        final StreamController controller = StreamController(
          onCancel: () {
            for (var e in stream.getTracks().toDart) {
              e.stop();
            }
          },
        );

        return controller.stream.listen((_) {});
      } else {
        for (var e in stream.getTracks().toDart) {
          e.stop();
        }
      }
    }

    return (const Stream.empty()).listen((_) {});
  }

  /// Requests the permission to use a microphone and holds it until
  /// unsubscribed.
  static Future<StreamSubscription<void>> microphonePermission() async {
    bool granted = false;

    // Firefox doesn't allow to check whether app has microphone permission:
    // https://searchfox.org/mozilla-central/source/dom/webidl/Permissions.webidl#10
    if (!isFirefox) {
      final permission = await web.window.navigator.permissions
          .query({'name': 'microphone'}.jsify() as JSObject)
          .toDart;
      granted = permission.state == 'granted';
    }

    // PWA in Safari returns `true` regarding permission, yet doesn't allow to
    // enumerate devices despite that.
    if (!granted || WebUtils.isSafari) {
      final web.MediaStream stream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
          .toDart;

      if (isFirefox) {
        final StreamController controller = StreamController(
          onCancel: () {
            for (var e in stream.getTracks().toDart) {
              e.stop();
            }
          },
        );

        return controller.stream.listen((_) {});
      } else {
        for (var e in stream.getTracks().toDart) {
          e.stop();
        }
      }
    }

    return (const Stream.empty()).listen((_) {});
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
          e
              .getProperty('href'.toJS)
              ?.toString()
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
          e
              .getProperty('href'.toJS)
              .toString()
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
    web.document.getElementById('page-loader')?.remove();
    web.document.getElementById('call-loader')?.remove();
  }

  /// Registers the custom [Config.scheme].
  static Future<void> registerScheme() async {
    // No-op.
  }

  /// Plays the provided [asset].
  ///
  /// If the returned [Stream] is canceled, then the playback stops.
  static Stream<void> play(String asset, {bool loop = false}) {
    Log.debug('play($asset, loop: $loop)', 'WebUtils');

    StreamController? controller;
    StreamSubscription? onEnded;
    web.AudioBufferSourceNode? node;

    controller = StreamController(
      onListen: () async {
        _context ??= web.AudioContext();
        if (_context?.state == 'suspended') {
          Log.debug(
            'play($asset, loop: $loop) -> _context?.state == `suspended`, resuming',
            'WebUtils',
          );

          await (_context?.resume())?.toDart;
        }

        if (controller?.hasListener == false) {
          return;
        }

        if (_context == null) {
          throw Exception('AudioContext is `null`, cannot `play($asset)`');
        }

        final web.AudioBufferSourceNode source = _context!.createBufferSource();

        final Response bytes = await (await PlatformUtils.dio).get(
          'assets/assets/$asset',
          options: Options(responseType: ResponseType.bytes),
        );

        if (controller?.hasListener == false) {
          return;
        }

        final JSPromise<web.AudioBuffer> audioBuffer = _context!
            .decodeAudioData((bytes.data as Uint8List).buffer.toJS);

        node = source;
        source.buffer = await audioBuffer.toDart;

        if (controller?.hasListener == false) {
          return;
        }

        source.loop = loop;
        source.connect(_context!.destination);
        source.start();
        onEnded = source.onEnded.listen((_) {
          controller?.close();
        });
      },
      onCancel: () {
        onEnded?.cancel();
        node?.stop();
        controller?.close();
      },
    );

    return controller.stream;
  }

  /// Returns the `User-Agent` header to put in the network queries.
  static Future<String> get userAgent async {
    final info = await DeviceInfoPlugin().webBrowserInfo;
    return info.userAgent ??
        '${Config.userAgentProduct}/${Config.userAgentVersion}';
  }

  /// Binds the [handler] to be invoked on the [key] presses.
  static Future<void> bindKey(HotKey key, bool Function() handler) async {
    if (_keyHandlers.isEmpty) {
      HardwareKeyboard.instance.addHandler(_handleBindKeys);
    }

    final List<bool Function()>? contained = _keyHandlers[key];
    if (contained == null) {
      _keyHandlers[key] = [handler];
    } else {
      contained.add(handler);
    }
  }

  /// Unbinds the [handler] from the [key].
  static Future<void> unbindKey(HotKey key, bool Function() handler) async {
    final list = _keyHandlers[key];
    list?.remove(handler);

    if (list?.isEmpty == true) {
      _keyHandlers.remove(key);
    }

    if (_keyHandlers.isEmpty) {
      HardwareKeyboard.instance.removeHandler(_handleBindKeys);
    }
  }

  /// Refreshes the current browser's page.
  static Future<void> refresh() async {
    web.window.location.reload();
  }

  /// Downloads the provided [bytes] as a blob file.
  static Future<void> downloadBlob(String name, Uint8List bytes) async {
    final JSPromise promise = _webSaveAs(
      web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: 'text/plain;charset=utf-8'),
      ),
      name.toJS,
    );

    await promise.toDart;
  }

  /// Refreshes the current browser's page.
  static void setBadge(int count) {
    Log.debug(
      'setAppBadge($count) -> closure is `null`? ${setAppBadgeClosure == null}',
      'WebUtils',
    );

    if (setAppBadgeClosure != null) {
      if (count > 0) {
        setAppBadge(count);
      } else {
        clearAppBadge();
      }
    }
  }

  /// Ensures foreground service is running to support receiving microphone
  /// input when application is in background.
  ///
  /// Does nothing on non-Android operating systems.
  static Future<void> setupForegroundService() async {
    // No-op.
  }

  /// Registers the plugins having separate implementations for web and non-web
  /// platforms.
  static void registerWith() {
    VideoPlayerPlugin.registerWith(webPluginRegistrar);
  }

  /// Handles the [key] event to invoke [_keyHandlers] related to it.
  static bool _handleBindKeys(KeyEvent key) {
    if (key is KeyUpEvent) {
      for (var e in _keyHandlers.entries) {
        if (e.key.key == key.physicalKey) {
          bool modifiers = true;

          for (var m in e.key.modifiers ?? <HotKeyModifier>[]) {
            modifiers =
                modifiers &&
                switch (m) {
                  HotKeyModifier.alt => HardwareKeyboard.instance.isAltPressed,
                  HotKeyModifier.capsLock =>
                    HardwareKeyboard.instance.isPhysicalKeyPressed(
                      PhysicalKeyboardKey.capsLock,
                    ),
                  HotKeyModifier.control =>
                    HardwareKeyboard.instance.isControlPressed,
                  HotKeyModifier.fn =>
                    HardwareKeyboard.instance.isPhysicalKeyPressed(
                      PhysicalKeyboardKey.fn,
                    ),
                  HotKeyModifier.meta =>
                    HardwareKeyboard.instance.isMetaPressed,
                  HotKeyModifier.shift =>
                    HardwareKeyboard.instance.isShiftPressed,
                };
          }

          if (modifiers) {
            for (var f in e.value) {
              if (f()) {
                return true;
              }
            }
          }
        }
      }
    }

    return false;
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
    (data['left'] as num).toDouble(),
    (data['top'] as num).toDouble(),
    (data['width'] as num).toDouble(),
    (data['height'] as num).toDouble(),
  );
}

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
import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:win_toast/win_toast.dart';
import 'package:window_manager/window_manager.dart';

import '/routes.dart';
import '/util/audio_utils.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'disposable_service.dart';

/// Service responsible for notifications management.
class NotificationService extends DisposableService {
  /// Instance of a [FlutterLocalNotificationsPlugin] used to send notifications
  /// on non-web platforms.
  FlutterLocalNotificationsPlugin? _plugin;

  /// Subscription to the [PlatformUtils.onActivityChanged] updating the
  /// [_active].
  StreamSubscription? _onActivityChanged;

  /// Indicator whether the application is active.
  bool _active = true;

  /// Xml data used to show local notifications on Windows.
  String? _notificationXml;

  /// Initializes this [NotificationService].
  ///
  /// Requests permission to send notifications if it hasn't been granted yet.
  ///
  /// Optional [onNotificationResponse] callback is called when user taps on a
  /// notification.
  ///
  /// Optional [onDidReceiveLocalNotification] callback is called
  /// when a notification is triggered while the app is in the foreground and is
  /// only applicable to iOS versions older than 10.
  Future<void> init({
    void Function(NotificationResponse)? onNotificationResponse,
    void Function(int, String?, String?, String?)?
        onDidReceiveLocalNotification,
  }) async {
    PlatformUtils.isActive.then((value) => _active = value);
    _onActivityChanged =
        PlatformUtils.onActivityChanged.listen((v) => _active = v);

    AudioUtils.ensureInitialized();

    if (PlatformUtils.isWeb) {
      // Permission request is happening in `index.html` via a script tag due to
      // a browser's policy to ask for notifications permission only after
      // user's interaction.
      WebUtils.onSelectNotification = onNotificationResponse;
    } else {
      if (PlatformUtils.isWindows) {
        await WinToast.instance().initialize(
          aumId: 'team113.messenger',
          displayName: 'Gapopa',
          iconPath:
              File(r'windows\runner\resources\app_icon.ico').absolute.path,
          // TODO: Use a real clsid.
          clsid: '00000000-0000-0000-0000-000000000000',
        );

        WinToast.instance().setActivatedCallback((event) async {
          await WindowManager.instance.focus();
          if (event.argument.isNotEmpty) {
            router.push(event.argument);
          }
        });
      } else if (_plugin == null) {
        _plugin = FlutterLocalNotificationsPlugin();
        await _plugin!.initialize(
          InitializationSettings(
            android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(
              onDidReceiveLocalNotification: onDidReceiveLocalNotification,
            ),
            macOS: const DarwinInitializationSettings(),
            linux:
                const LinuxInitializationSettings(defaultActionName: 'click'),
          ),
          onDidReceiveNotificationResponse: onNotificationResponse,
          onDidReceiveBackgroundNotificationResponse: onNotificationResponse,
        );
      }
    }
  }

  @override
  void onClose() {
    _onActivityChanged?.cancel();
  }

  // TODO: Implement icons and attachments on non-web platforms.
  /// Shows a notification with a [title] and an optional [body] and [icon].
  ///
  /// Use [payload] to embed information into the notification.
  Future<void> show(
    String title, {
    String? body,
    String? payload,
    String? icon,
    String? tag,
    bool playSound = true,
  }) async {
    // If application is in focus and the payload is the current route, then
    // don't show a local notification.
    if (_active && payload == router.route) return;

    if (playSound) {
      AudioUtils.once(AudioSource.asset('audio/notification.mp3'));
    }

    if (PlatformUtils.isWeb) {
      WebUtils.showNotification(
        title,
        body: body,
        lang: payload,
        icon: icon,
        tag: tag,
      ).onError((_, __) => false);
    }
    if (PlatformUtils.isWindows) {
      await _showWindowsNotification(title: title, body: body, launch: payload);
    } else {
      // TODO: `flutter_local_notifications` should support Windows:
      //       https://github.com/MaikuB/flutter_local_notifications/issues/746
      await _plugin!.show(
        Random().nextInt(1 << 31),
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'com.team113.messenger',
            'Gapopa',
            playSound: playSound,
            sound: const RawResourceAndroidNotificationSound('notification'),
          ),
        ),
        payload: payload,
      );
    }
  }

  /// Shows a local notification on Windows with the provided data.
  Future<void> _showWindowsNotification({
    required String title,
    String? body,
    String? launch,
  }) async {
    _notificationXml ??= await rootBundle.loadString(
      'assets/windows_notifications/notification.xml',
    );

    String xml = _notificationXml!
        .replaceFirst('##title##', title)
        .replaceFirst('##body##', body ?? '')
        .replaceFirst('##launch##', launch ?? '');

    await WinToast.instance().showCustomToast(
      xml: xml,
      tag: 'Gapopa',
    );
  }
}

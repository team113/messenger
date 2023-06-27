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
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import '/routes.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'disposable_service.dart';

/// Service responsible for notifications management.
class NotificationService extends DisposableService {
  /// Instance of a [FlutterLocalNotificationsPlugin] used to send notifications
  /// on non-web platforms.
  FlutterLocalNotificationsPlugin? _plugin;

  /// [AudioPlayer] playing a notification sound.
  AudioPlayer? _audioPlayer;

  /// Subscription to the [PlatformUtils.onActivityChanged] updating the
  /// [_active].
  StreamSubscription? _onActivityChanged;

  /// Indicator whether the application is active.
  bool _active = true;

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

    _initAudio();
    if (PlatformUtils.isWeb) {
      // Permission request is happening in `index.html` via a script tag due to
      // a browser's policy to ask for notifications permission only after
      // user's interaction.
      WebUtils.onSelectNotification = onNotificationResponse;
    } else {
      if (_plugin == null) {
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
    _audioPlayer?.dispose();
    _audioPlayer = null;
    AudioCache.instance.clear('audio/notification.mp3');
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
      runZonedGuarded(() async {
        await _audioPlayer?.play(
          AssetSource('audio/notification.mp3'),
          position: Duration.zero,
          mode: PlayerMode.lowLatency,
        );
      }, (e, _) {
        if (!e.toString().contains('NotAllowedError')) {
          throw e;
        }
      });
    }

    if (PlatformUtils.isWeb) {
      WebUtils.showNotification(
        title,
        body: body,
        lang: payload,
        icon: icon,
        tag: tag,
      ).onError((_, __) => false);
    } else if (!PlatformUtils.isWindows) {
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

  /// Initializes the [_audioPlayer].
  Future<void> _initAudio() async {
    // [AudioPlayer] constructor creates a hanging [Future], which can't be
    // awaited.
    await runZonedGuarded(
      () async {
        _audioPlayer = AudioPlayer(playerId: 'notificationPlayer');
        await AudioCache.instance.loadAll(['audio/notification.mp3']);
      },
      (e, _) {
        if (e is MissingPluginException) {
          _audioPlayer = null;
        } else {
          throw e;
        }
      },
    );
  }
}

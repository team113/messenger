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

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import '/config.dart';
import '/domain/model/fcm_registration_token.dart';
import '/provider/gql/graphql.dart';
import '/routes.dart';
import '/util/android_utils.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'disposable_service.dart';

/// Service responsible for notifications management.
class NotificationService extends DisposableService {
  NotificationService(this._graphQlProvider);

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// Language used in FCM notifications.
  String? _language;

  /// FCM token used to subscribe for push notifications.
  String? _token;

  /// Instance of a [FlutterLocalNotificationsPlugin] used to send notifications
  /// on non-web platforms.
  FlutterLocalNotificationsPlugin? _plugin;

  /// [AudioPlayer] playing a notification sound.
  AudioPlayer? _audioPlayer;

  /// Subscription to the [PlatformUtils.onFocusChanged] updating the
  /// [_focused].
  StreamSubscription? _onFocusChanged;

  /// Subscription to the [FirebaseMessaging.onTokenRefresh].
  StreamSubscription? _onTokenRefresh;

  /// [StreamSubscription] on the [FirebaseMessaging.onMessage] stream.
  StreamSubscription? _foregroundSubscription;

  /// Indicator whether the application's window is in focus.
  bool _focused = true;

  /// Initializes this [NotificationService].
  ///
  /// Requests permission to send notifications if it hasn't been granted yet.
  ///
  /// Optional [onLocalNotificationResponse] callback is called when user taps
  /// on a local notification.
  ///
  /// Optional [onFcmNotificationResponse] callback is called when user taps on
  /// a FCM notification.
  ///
  /// Optional [onFcmBackgroundNotificationResponse] callback is called when a
  /// FCM notification received and the app is in the background or terminated
  /// state.
  void init({
    String? language,
    FirebaseOptions? firebaseOptions,
    void Function(NotificationResponse)? onLocalNotificationResponse,
    void Function(RemoteMessage message)? onFcmNotificationResponse,
    Future<void> Function(RemoteMessage message)?
        onFcmBackgroundNotificationResponse,
  }) async {
    _language = language;

    PlatformUtils.isFocused.then((value) => _focused = value);
    _onFocusChanged = PlatformUtils.onFocusChanged.listen((v) => _focused = v);

    _initAudio();
    _initLocalNotifications(onLocalNotificationResponse);

    try {
      await _initPushNotifications(
        firebaseOptions: firebaseOptions,
        onFcmNotificationResponse: onFcmNotificationResponse,
        onFcmBackgroundNotificationResponse:
            onFcmBackgroundNotificationResponse,
      );
    } catch (e) {
      Log.print(
        'Failed to initialize push notifications: $e',
        'NotificationService',
      );
    }
  }

  @override
  void onClose() {
    _onFocusChanged?.cancel();
    _onTokenRefresh?.cancel();
    _foregroundSubscription?.cancel();
    _audioPlayer?.dispose();
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
    String? image,
  }) async {
    // If application is in focus and the payload is the current route, then
    // don't show a local notification.
    if (_focused && payload == router.route) return;

    // Android plays the notification sound itself when showing a notification.
    if (playSound && !PlatformUtils.isAndroid) {
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

    Uint8List? imageBytes;
    String? imagePath;

    // In order to show an image in local notification, Android requires bytes
    // of that image fetched, while iOS and macOS require path to it.
    if (!PlatformUtils.isWeb && image != null) {
      if (PlatformUtils.isAndroid) {
        try {
          final Response response = await PlatformUtils.dio.get(
            image,
            options: Options(responseType: ResponseType.bytes),
          );

          if (response.statusCode == 200) {
            imageBytes = response.data;
          }
        } catch (_) {
          // No-op.
        }
      } else if (PlatformUtils.isIOS || PlatformUtils.isMacOS) {
        try {
          final File? file = await PlatformUtils.download(
            image,
            'notification_image_${DateTime.now()}',
            null,
          );

          if (file != null) {
            imagePath = file.path;
          }
        } catch (_) {
          // No-op.
        }
      }
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
            'Default',
            playSound: playSound,
            sound: const RawResourceAndroidNotificationSound('notification'),
            largeIcon:
                imageBytes == null ? null : ByteArrayAndroidBitmap(imageBytes),
          ),
          iOS: DarwinNotificationDetails(
            sound: 'notification.caf',
            attachments: [
              if (imagePath != null) DarwinNotificationAttachment(imagePath)
            ],
          ),
          macOS: DarwinNotificationDetails(
            sound: 'notification.caf',
            attachments: [
              if (imagePath != null) DarwinNotificationAttachment(imagePath)
            ],
          ),
        ),
        payload: payload,
      );
    }
  }

  /// Updates the [_language] and resubscribes for FCM notifications.
  void updateLanguage(String? language) async {
    if (_language != language) {
      _language = language;

      if (_token != null) {
        await _graphQlProvider
            .unregisterFcmDevice(FcmRegistrationToken(_token!));

        await _graphQlProvider.registerFcmDevice(
          FcmRegistrationToken(_token!),
          _language,
        );
      }
    }
  }

  /// Initializes the [_audioPlayer].
  Future<void> _initAudio() async {
    try {
      _audioPlayer = AudioPlayer(playerId: 'notificationPlayer');
      await AudioCache.instance.loadAll(['audio/notification.mp3']);
    } on MissingPluginException {
      _audioPlayer = null;
    }
  }

  /// Initializes [FlutterLocalNotificationsPlugin] for showing local
  /// notifications.
  Future<void> _initLocalNotifications(
    void Function(NotificationResponse)? onNotificationResponse,
  ) async {
    if (PlatformUtils.isWeb) {
      // Permission request is happening in `index.html` via a script tag due to
      // a browser's policy to ask for notifications permission only after
      // user's interaction.
      WebUtils.onSelectNotification = onNotificationResponse;
    } else {
      if (_plugin == null) {
        _plugin = FlutterLocalNotificationsPlugin();

        try {
          await _plugin!.initialize(
            const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(),
              macOS: DarwinInitializationSettings(),
              linux: LinuxInitializationSettings(defaultActionName: 'click'),
            ),
            onDidReceiveNotificationResponse: onNotificationResponse,
            onDidReceiveBackgroundNotificationResponse: onNotificationResponse,
          );

          if (!PlatformUtils.isWindows) {
            final NotificationAppLaunchDetails? details =
                await _plugin!.getNotificationAppLaunchDetails();

            if (details?.notificationResponse != null) {
              onNotificationResponse?.call(details!.notificationResponse!);
            }
          }
        } on MissingPluginException {
          _plugin = null;
        }
      }
    }
  }

  /// Initializes the [FirebaseMessaging] for receiving push notifications.
  Future<void> _initPushNotifications({
    FirebaseOptions? firebaseOptions,
    void Function(RemoteMessage message)? onFcmNotificationResponse,
    Future<void> Function(RemoteMessage message)?
        onFcmBackgroundNotificationResponse,
  }) async {
    if (PlatformUtils.pushNotifications && !WebUtils.isPopup) {
      if (onFcmBackgroundNotificationResponse != null) {
        FirebaseMessaging.onBackgroundMessage(
          onFcmBackgroundNotificationResponse,
        );
      }
      FirebaseMessaging.onMessageOpenedApp.listen(onFcmNotificationResponse);

      await Firebase.initializeApp(options: firebaseOptions);

      final RemoteMessage? initial =
          await FirebaseMessaging.instance.getInitialMessage();

      if (initial != null) {
        onFcmNotificationResponse?.call(initial);
      }

      _foregroundSubscription = FirebaseMessaging.onMessage.listen((event) {
        if (event.notification != null && event.notification?.title != null) {
          show(
            event.notification!.title!,
            body: event.notification!.body,
            payload: '${Routes.chats}/${event.data['chatId']}',
            image: event.notification!.android?.imageUrl,
          );
        }
      });

      if (PlatformUtils.isAndroid && !PlatformUtils.isWeb) {
        await AndroidUtils.createNotificationChanel(
          id: 'com.team113.messenger',
          name: 'Default',
          sound: 'notification',
        );
      }

      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission();

      // First attempt always failed on the first startup.
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        settings = await FirebaseMessaging.instance.requestPermission();
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _token = await FirebaseMessaging.instance.getToken(
          vapidKey: Config.vapidKey,
        );

        if (_token != null) {
          _graphQlProvider.registerFcmDevice(
            FcmRegistrationToken(_token!),
            _language,
          );
        }

        _onTokenRefresh =
            FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
          if (_token != null) {
            await _graphQlProvider
                .unregisterFcmDevice(FcmRegistrationToken(_token!));
          }

          _token = token;
          _graphQlProvider.registerFcmDevice(
            FcmRegistrationToken(_token!),
            _language,
          );
        });
      }
    }
  }
}

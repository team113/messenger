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

  /// GraphQL API provider for registering and un-registering current device for
  /// receiving Firebase Cloud Messaging notifications.
  final GraphQlProvider _graphQlProvider;

  /// Language to receive Firebase Cloud Messaging notifications on.
  String? _language;

  /// Firebase Cloud Messaging token used to subscribe for push notifications.
  String? _token;

  /// Instance of a [FlutterLocalNotificationsPlugin] used to send notifications
  /// on non-web platforms.
  FlutterLocalNotificationsPlugin? _plugin;

  /// Subscription to the [PlatformUtils.onFocusChanged] updating the
  /// [_focused].
  StreamSubscription? _onFocusChanged;

  /// Subscription to the [FirebaseMessaging.onTokenRefresh].
  StreamSubscription? _onTokenRefresh;

  /// [StreamSubscription] to the [FirebaseMessaging.onMessage] stream.
  StreamSubscription? _foregroundSubscription;

  /// Indicator whether the application's window is in focus.
  bool _focused = true;

  /// Tags of the local notifications that were displayed.
  ///
  /// Used to discard displaying a local notification second time when it is
  /// received via the [_foregroundSubscription].
  final List<String> _tags = [];

  /// Initializes this [NotificationService].
  ///
  /// Requests permission to send notifications if it hasn't been granted yet.
  ///
  /// Optional [onResponse] callback is called when user taps on a notification.
  ///
  /// Optional [onBackground] callback is called when a notification is received
  /// when the application is in the background or terminated. Note that this
  /// callback must be a top-level entry function, as it is launched in a
  /// background isolate.
  Future<void> init({
    String? language,
    FirebaseOptions? firebaseOptions,
    void Function(String)? onResponse,
    Future<void> Function(RemoteMessage message)? onBackground,
  }) async {
    _language = language ?? _language;

    PlatformUtils.isFocused.then((value) => _focused = value);
    _onFocusChanged = PlatformUtils.onFocusChanged.listen((v) => _focused = v);

    _initLocalNotifications(
      onResponse: (NotificationResponse response) {
        if (response.payload != null) {
          onResponse?.call(response.payload!);
        }
      },
    );

    try {
      await _initPushNotifications(
        options: firebaseOptions,
        onResponse: (RemoteMessage message) {
          if (message.data['chatId'] != null) {
            onResponse?.call('${Routes.chats}/${message.data['chatId']}');
          }
        },
        onBackground: onBackground,
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
    String? image,
  }) async {
    // Don't display a notification with the provided [tag], if it's in the
    // [_tags] list already, or otherwise add it to that list.
    if (_foregroundSubscription != null && tag != null) {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
        return;
      } else {
        _tags.add(tag);
      }
    }

    // If application is in focus and the payload is the current route, then
    // don't show a local notification.
    if (_focused && payload == router.route) {
      return;
    }

    if (PlatformUtils.isWeb) {
      WebUtils.showNotification(
        title,
        body: body,
        lang: payload,
        icon: icon ?? image,
        tag: tag,
      ).onError((_, __) => false);
    } else if (!PlatformUtils.isWindows) {
      String? imagePath;

      // In order to show an image in local notification, we need to download it
      // first to a [File] and then pass the path to it to the plugin.
      if (image != null) {
        try {
          final File? file = await PlatformUtils.download(
            image,
            'notification_${DateTime.now()}.jpg',
            null,
            temporary: true,
          );

          imagePath = file?.path;
        } catch (_) {
          // No-op.
        }
      }

      // TODO: `flutter_local_notifications` should support Windows:
      //       https://github.com/MaikuB/flutter_local_notifications/issues/746
      await _plugin!.show(
        // On Android notifications are replaced when ID and tag are the same,
        // and FCM notifications always have ID of zero, so in order for push
        // notifications to replace local, we set there zero as well.
        PlatformUtils.isAndroid ? 0 : Random().nextInt(1 << 31),
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'default',
            'Default',
            sound: const RawResourceAndroidNotificationSound('notification'),
            styleInformation: imagePath == null
                ? null
                : BigPictureStyleInformation(FilePathAndroidBitmap(imagePath)),
            tag: tag,
          ),
          linux: LinuxNotificationDetails(
            sound: AssetsLinuxSound('audio/notification.mp3'),
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

  /// Sets the provided [language] as a preferred localization of the push
  /// notifications.
  void setLanguage(String? language) async {
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

  /// Initializes the [FlutterLocalNotificationsPlugin] for displaying the local
  /// notifications.
  Future<void> _initLocalNotifications({
    void Function(NotificationResponse)? onResponse,
  }) async {
    if (PlatformUtils.isWeb) {
      // Permission request is happening in `index.html` via a script tag due to
      // a browser's policy to ask for notifications permission only after
      // user's interaction.
      WebUtils.onSelectNotification = onResponse;
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
            onDidReceiveNotificationResponse: onResponse,
          );

          if (!PlatformUtils.isWindows) {
            final NotificationAppLaunchDetails? details =
                await _plugin!.getNotificationAppLaunchDetails();

            if (details?.notificationResponse != null) {
              onResponse?.call(details!.notificationResponse!);
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
    FirebaseOptions? options,
    void Function(RemoteMessage message)? onResponse,
    Future<void> Function(RemoteMessage message)? onBackground,
  }) async {
    if (PlatformUtils.pushNotifications && !WebUtils.isPopup) {
      FirebaseMessaging.onMessageOpenedApp.listen(onResponse);

      if (onBackground != null) {
        FirebaseMessaging.onBackgroundMessage(onBackground);
      }

      await Firebase.initializeApp(options: options);

      final RemoteMessage? initial =
          await FirebaseMessaging.instance.getInitialMessage();

      if (initial != null) {
        onResponse?.call(initial);
      }

      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        if (message.notification?.title != null) {
          show(
            message.notification!.title!,
            body: message.notification?.body,
            payload: message.data['chatId'] != null
                ? '${Routes.chats}/${message.data['chatId']}'
                : null,
            image: message.notification?.android?.imageUrl ??
                message.notification?.apple?.imageUrl ??
                message.notification?.web?.image,
            tag: message.data['chatItemId'],
          );
        }
      });

      if (PlatformUtils.isAndroid && !PlatformUtils.isWeb) {
        await AndroidUtils.createNotificationChannel(
          id: 'default',
          name: 'Default',
          sound: 'notification',
        );
      }

      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission();

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

// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
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

import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:universal_io/io.dart';
import 'package:win_toast/win_toast.dart';
import 'package:window_manager/window_manager.dart';

import '/api/backend/schema.dart'
    show PushDeviceToken, RegisterPushDeviceErrorCode;
import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/file.dart';
import '/domain/model/push_token.dart';
import '/provider/gql/exceptions.dart' show RegisterPushDeviceException;
import '/provider/gql/graphql.dart';
import '/routes.dart';
import '/ui/worker/cache.dart';
import '/util/android_utils.dart';
import '/util/audio_utils.dart';
import '/util/ios_utils.dart';
import '/util/log.dart';
import '/util/macos_utils.dart';
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

  /// [FcmRegistrationToken] used to subscribe to FCM push notifications.
  String? _token;

  /// [ApnsDeviceToken] used to subscribe to APNs push notifications.
  String? _apns;

  /// [ApnsVoipDeviceToken] used to subscribe to APNs VoIP push notifications.
  String? _voip;

  /// Instance of a [FlutterLocalNotificationsPlugin] used to send notifications
  /// on non-web platforms.
  FlutterLocalNotificationsPlugin? _plugin;

  /// Subscription to the [FirebaseMessaging.onTokenRefresh] refreshing the
  /// [_token].
  StreamSubscription? _onTokenRefresh;

  /// [StreamSubscription] to the [FirebaseMessaging.onMessage] handling the
  /// push notifications in foreground.
  StreamSubscription? _foregroundSubscription;

  /// Subscription to the [PlatformUtilsImpl.onActivityChanged] updating the
  /// [_active].
  StreamSubscription? _onActivityChanged;

  /// Subscription to a [WebUtils.onBroadcastMessage] playing the notification
  /// sound on web platforms and updating the [_tags] when push notifications
  /// are received.
  StreamSubscription? _onBroadcastMessage;

  /// Subscription to the [WebUtils.onBroadcastMessage] changing the [router]
  /// location.
  StreamSubscription? _onRouteMessage;

  /// Indicator whether the application is active.
  bool _active = true;

  /// Tags of the notifications that were displayed.
  ///
  /// Used to discard displaying a local notification when another notification
  /// with the same tag has already been received, for example, via the
  /// [_foregroundSubscription].
  final List<String> _tags = [];

  /// Indicator whether the Firebase Cloud Messaging notifications are
  /// successfully configured.
  bool _pushNotifications = false;

  /// Indicates whether the Firebase Cloud Messaging notifications are
  /// successfully configured.
  bool get pushNotifications => _pushNotifications;

  /// Returns the [DeviceToken] that is used for push notifications.
  DeviceToken get token => DeviceToken(
    apns: _apns == null ? null : ApnsDeviceToken(_apns ?? ''),
    voip: _voip == null ? null : ApnsVoipDeviceToken(_voip ?? ''),
    fcm: _token == null ? null : FcmRegistrationToken(_token ?? ''),
  );

  /// Indicator whether this device's [Locale] contains a China country code.
  bool get _isChina => Platform.localeName.contains('CN');

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
    Log.debug(
      'init($language, firebaseOptions, onResponse, onBackground)',
      '$runtimeType',
    );

    if (WebUtils.isPopup) {
      return;
    }

    _language = language ?? _language;

    PlatformUtils.isActive.then((value) => _active = value);
    _onActivityChanged = PlatformUtils.onActivityChanged.listen(
      (v) => _active = v,
    );

    AudioUtils.ensureInitialized();

    _initLocalNotifications(
      onResponse: (NotificationResponse response) {
        if (response.payload != null) {
          onResponse?.call(response.payload!);
        }
      },
    );

    if (PlatformUtils.pushNotifications) {
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
        Log.error(
          'Failed to initialize push notifications: ${e.toString()}',
          '$runtimeType',
        );
      }
    }
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    _onTokenRefresh?.cancel();
    _foregroundSubscription?.cancel();
    _onActivityChanged?.cancel();
    _onBroadcastMessage?.cancel();
    _onRouteMessage?.cancel();
  }

  // TODO: Implement icons and attachments on non-web platforms.
  /// Shows a notification with a [title] and an optional [body] and [icon].
  ///
  /// Use [payload] to embed information into the notification.
  Future<void> show(
    String title, {
    String? body,
    String? payload,
    ImageFile? icon,
    String? tag,
    String? thread,
    String? image,
  }) async {
    Log.debug(
      'show($title, $body, $payload, $icon, $tag, $thread, $image) -> id is `${tag?.asHash}`',
      '$runtimeType',
    );

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

    // If application is in focus, the payload is the current route and nothing
    // is obscuring the screen, then don't show a local notification.
    if (_active && payload == router.route && router.obscuring.isEmpty) {
      return;
    }

    // Play a notification sound on Web and on Windows.
    //
    // Other platforms don't require playing a sound explicitly, as the local or
    // push notification displayed plays it instead.
    if (PlatformUtils.isWeb || PlatformUtils.isWindows) {
      AudioUtils.once(AudioSource.asset('audio/notification.mp3'));
    }

    if (PlatformUtils.isWeb) {
      WebUtils.showNotification(
        title,
        body: body,
        data: {
          'webpush': {'link': payload},
        },
        icon: icon?.url ?? image,
        tag: tag,
      ).onError((_, _) => false);
    } else if (PlatformUtils.isWindows) {
      File? file;
      if (icon != null) {
        file = (await CacheWorker.instance.get(
          url: icon.url,
          checksum: icon.checksum,
          responseType: CacheResponseType.file,
        )).file;
      }

      await WinToast.instance().showCustomToast(
        xml:
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<toast activationType="Foreground" launch="${payload ?? ''}">'
            '  <visual addImageQuery="true">'
            '      <binding template="ToastGeneric">'
            '          <text>$title</text>'
            '          <text>${body ?? ''}</text>'
            '          <image placement="appLogoOverride" hint-crop="circle" id="1" src="${file?.path ?? ''}"/>'
            '      </binding>'
            '  </visual>'
            '</toast>',
        tag: 'Tapopa',
      );
    } else {
      String? imagePath;

      // In order to show an image in local notification, we need to download it
      // first to a [File] and then pass the path to it to the plugin.
      if (image != null) {
        try {
          final String name =
              'notification_${DateTime.now().toString().replaceAll(':', '.')}.jpg';
          final File? file = await PlatformUtils.download(
            image,
            name,
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
      await _plugin?.show(
        tag?.asHash ?? Random().nextInt(1 << 31),
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
            groupKey: thread,
          ),
          linux: LinuxNotificationDetails(
            sound: AssetsLinuxSound('audio/notification.mp3'),
          ),
          iOS: DarwinNotificationDetails(
            sound: 'notification.caf',
            attachments: [
              if (imagePath != null) DarwinNotificationAttachment(imagePath),
            ],
            threadIdentifier: thread,
          ),
          macOS: DarwinNotificationDetails(
            sound: 'notification.caf',
            attachments: [
              if (imagePath != null) DarwinNotificationAttachment(imagePath),
            ],
            threadIdentifier: thread,
          ),
        ),
        payload: payload,
      );
    }
  }

  /// Sets the provided [language] as a preferred localization of the push
  /// notifications.
  Future<void> setLanguage(String? language) async {
    Log.debug('setLanguage($language) from $_language', '$runtimeType');

    if (_language != language) {
      _language = language;

      if (_token != null || _apns != null || _voip != null) {
        await unregisterPushDevice();
        await _registerPushDevice();
      }
    }
  }

  /// Clears all notifications for a specific chat by [chatId].
  Future<void> clearNotifications(ChatId chatId) async {
    Log.debug('clearNotifications($chatId)', '$runtimeType');

    if (PlatformUtils.isWeb) {
      return WebUtils.clearNotifications(chatId);
    }

    if (PlatformUtils.isIOS) {
      try {
        await IosUtils.cancelNotificationsContaining(chatId.val);
      } on MissingPluginException {
        // No-op, this can be expected.
      }
    }

    if (PlatformUtils.isMacOS) {
      try {
        await MacosUtils.cancelNotificationsContaining(chatId.val);
      } on MissingPluginException {
        // No-op, this can be expected.
      }
    }

    final FlutterLocalNotificationsPlugin? plugin = _plugin;

    if (plugin == null) {
      return;
    }

    final List<ActiveNotification> notifications = await plugin
        .getActiveNotifications();

    for (final notification in notifications) {
      if (notification.payload?.contains(chatId.val) == true ||
          notification.tag?.contains(chatId.val) == true) {
        final int? id = notification.id;

        if (id != null) {
          await plugin.cancel(id, tag: notification.tag);
        }
      }
    }
  }

  /// Initializes the [FlutterLocalNotificationsPlugin] for displaying the local
  /// notifications.
  Future<void> _initLocalNotifications({
    void Function(NotificationResponse)? onResponse,
  }) async {
    Log.debug('_initLocalNotifications(onResponse)', '$runtimeType');

    _onRouteMessage = WebUtils.onBroadcastMessage(name: 'route').listen((e) {
      Log.debug('_onRouteMessage() -> $e', '$runtimeType');

      if (e is String) {
        router.go(e);
      }
    });

    if (PlatformUtils.isWeb) {
      // Permission request is happening in `index.html` via a script tag due to
      // a browser's policy to ask for notifications permission only after
      // user's interaction.
      WebUtils.onSelectNotification = onResponse;
    } else if (PlatformUtils.isWindows) {
      await WinToast.instance().initialize(
        aumId: 'tapopa.messenger',
        displayName: 'Tapopa',
        iconPath: kDebugMode
            ? File(r'assets\icons\app_icon.ico').absolute.path
            : File(
                r'data\flutter_assets\assets\icons\app_icon.ico',
              ).absolute.path,
        clsid: Config.clsid,
      );

      WinToast.instance().setActivatedCallback((event) async {
        await WindowManager.instance.focus();

        onResponse?.call(
          NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: event.argument.isEmpty ? null : event.argument,
          ),
        );
      });
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
            final NotificationAppLaunchDetails? details = await _plugin!
                .getNotificationAppLaunchDetails();

            if (details?.notificationResponse != null) {
              onResponse?.call(details!.notificationResponse!);
            }
          }
        } on MissingPluginException {
          _plugin = null;
        } on UnimplementedError {
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
    Log.debug(
      '_initPushNotifications(options, onResponse, onBackground)',
      '$runtimeType',
    );

    try {
      await Firebase.initializeApp(options: options);
    } catch (e) {
      if (e.toString().contains('[core/duplicate-app]')) {
        // No-op.
      } else {
        rethrow;
      }
    }

    FirebaseMessaging.onMessageOpenedApp.listen(onResponse);

    if (onBackground != null) {
      FirebaseMessaging.onBackgroundMessage(onBackground);
    }

    final RemoteMessage? initial = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initial != null) {
      onResponse?.call(initial);
    }

    // Display a local notification, if there's any push notifications received
    // while application is in foreground.
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) async {
      Log.debug('_foregroundSubscription(${message.toMap()})', '$runtimeType');

      final String? tag = message.data['tag'];
      final String? thread = message.data['thread'];

      if (tag != null) {
        await AndroidUtils.cancelNotificationById(tag, tag.asHash);
      }

      // If message contains no notification (it's a background notification),
      // then try canceling the notifications with the provided thread, if any,
      // or otherwise a single one, if data contains a tag.
      if (message.notification == null ||
          (message.notification?.title?.isEmpty != false &&
              message.notification?.body == null)) {
        if (PlatformUtils.isWeb) {
          // TODO: Implement notifications canceling for Web.
        } else if (PlatformUtils.isAndroid) {
          if (thread != null) {
            await AndroidUtils.cancelNotificationsContaining(thread);
          } else if (tag != null) {
            await AndroidUtils.cancelNotification(tag);
          }
        } else if (PlatformUtils.isIOS) {
          if (thread != null) {
            await IosUtils.cancelNotificationsContaining(thread);
          } else if (tag != null) {
            await IosUtils.cancelNotification(tag);
          }
        }
      } else if (message.notification?.title != null) {
        await show(
          message.notification!.title!,
          body: message.notification?.body,
          payload: message.data['chatId'] != null
              ? '${Routes.chats}/${message.data['chatId']}'
              : null,
          image:
              message.notification?.android?.imageUrl ??
              message.notification?.apple?.imageUrl ??
              message.notification?.web?.image,
          thread: message.data['chatId'],
          tag:
              message.data['chatId'] != null &&
                  message.data['chatItemId'] != null
              ? '${message.data['chatId']}-${message.data['chatItemId']}'
              : null,
        );
      }
    });

    // Create a notification channel on Android to play custom notification
    // sound.
    if (PlatformUtils.isAndroid && !PlatformUtils.isWeb) {
      try {
        await AndroidUtils.createNotificationChannel(
          id: 'default',
          name: 'Default',
          sound: 'notification',
        );
      } catch (e) {
        Log.error(e.toString(), '$runtimeType');
      }
    }

    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission();

    // On Android first attempt is always [AuthorizationStatus.denied] due to
    // notifications request popping while invoking a
    // [AndroidUtils.createNotificationChannel], so try again on failure.
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined ||
        (PlatformUtils.isAndroid &&
            settings.authorizationStatus != AuthorizationStatus.authorized)) {
      settings = await FirebaseMessaging.instance.requestPermission();
    }

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      Log.warning(
        'Unable to proceed with `_initPushNotifications()` due to `authorizationStatus` being `${settings.authorizationStatus.name}`',
      );
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _onBroadcastMessage = WebUtils.onBroadcastMessage().listen((message) {
        final String? chatId = message['data']?['chatId'];
        final String? chatItemId = message['data']?['chatItemId'];

        final String? tag = (chatId != null && chatItemId != null)
            ? '$chatId-$chatItemId'
            : null;

        // Keep track of the shown notifications' [tag]s to prevent duplication.
        //
        // Don't play a sound if the notification with the same [tag] has
        // already been shown.
        if (tag != null) {
          if (_tags.contains(tag)) {
            _tags.remove(tag);
            return;
          } else {
            _tags.add(tag);
          }
        }

        if (message['notification']?['title'] != null) {
          // On Web push notifications don't support playing any sounds, it's up
          // to operating system to decide, whether to play sound at all, so we
          // play a sound manually.
          AudioUtils.once(AudioSource.asset('audio/notification.mp3'));
        }
      });

      if (!PlatformUtils.isWeb && PlatformUtils.isIOS) {
        _voip = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
        _apns = await FirebaseMessaging.instance.getAPNSToken();
      }

      if (_apns == null) {
        _token = await FirebaseMessaging.instance.getToken(
          vapidKey: Config.vapidKey,
        );

        _onTokenRefresh = FirebaseMessaging.instance.onTokenRefresh.listen((
          token,
        ) async {
          await unregisterPushDevice();
          _token = token;
          await _registerPushDevice();
        });
      }

      await _registerPushDevice();
    }
  }

  /// Registers a device (Android, iOS, or Web) for receiving notifications.
  Future<void> _registerPushDevice() async {
    Log.debug('_registerPushDevice()', '$runtimeType');

    _pushNotifications = false;

    Log.debug('_registerPushDevice() -> _token: $_token', '$runtimeType');
    Log.debug('_registerPushDevice() -> _apns: $_apns', '$runtimeType');
    Log.debug('_registerPushDevice() -> _voip: $_voip', '$runtimeType');

    final List<Future> futures = [];

    if (_token != null) {
      futures.add(
        _registerWith(PushDeviceToken(fcm: FcmRegistrationToken(_token!))),
      );
    }

    if (_apns != null) {
      futures.add(
        _registerWith(PushDeviceToken(apns: ApnsDeviceToken(_apns!))),
      );
    }

    // CallKit should not be used in China due to restrictions.
    if (!_isChina) {
      if (_voip != null) {
        futures.add(
          _registerWith(PushDeviceToken(apnsVoip: ApnsVoipDeviceToken(_voip!))),
        );
      }
    }

    await Future.wait(futures);
  }

  /// Registers the device with the provided [token] as a [PushDeviceToken].
  Future<void> _registerWith(PushDeviceToken token) async {
    try {
      await _graphQlProvider.registerPushDevice(token, _language);
    } on RegisterPushDeviceException catch (e) {
      switch (e.code) {
        case RegisterPushDeviceErrorCode.occupied:
          // Expected, thus no-op.
          break;

        case RegisterPushDeviceErrorCode.artemisUnknown:
        case RegisterPushDeviceErrorCode.unknownDeviceToken:
        case RegisterPushDeviceErrorCode.unavailable:
        case null:
          rethrow;
      }
    }

    // VoIP notifications shouldn't be considered as push enabled notifications.
    if (token.apns != null || token.fcm != null) {
      _pushNotifications = true;
    }
  }

  /// Unregisters a device (Android, iOS, or Web) from receiving notifications.
  Future<void> unregisterPushDevice() async {
    Log.debug('unregisterPushDevice()', '$runtimeType');

    Log.debug('unregisterPushDevice() -> _token: $_token', '$runtimeType');
    Log.debug('unregisterPushDevice() -> _apns: $_apns', '$runtimeType');
    Log.debug('unregisterPushDevice() -> _voip: $_voip', '$runtimeType');

    try {
      await Future.wait([
        if (_token != null)
          _graphQlProvider.unregisterPushDevice(
            PushDeviceToken(fcm: FcmRegistrationToken(_token!)),
          ),
        if (_apns != null)
          _graphQlProvider.unregisterPushDevice(
            PushDeviceToken(apns: ApnsDeviceToken(_apns!)),
          ),
        if (_voip != null)
          _graphQlProvider.unregisterPushDevice(
            PushDeviceToken(apnsVoip: ApnsVoipDeviceToken(_voip!)),
          ),
      ]);
    } finally {
      _pushNotifications = false;
    }
  }
}

/// Extension adding simplest possible hash to a [String].
extension TagToHash on String {
  /// Returns a hash of this [String] in its simplest form.
  ///
  /// Currently uses [FNV-1a] hash function.
  ///
  /// [FNV-1a]: https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function
  int get asHash {
    int result = 0x811c9dc5;

    for (var e in codeUnits) {
      result ^= e;
      result *= 0x01000193;
      result &= 0xFFFFFFFF;
    }

    return result;
  }
}

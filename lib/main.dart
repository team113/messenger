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

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:log_me/log_me.dart' as me;
import 'package:pwa_install/pwa_install.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'api/backend/schema.dart';
import 'config.dart';
import 'domain/model/chat.dart';
import 'domain/model/session.dart';
import 'domain/model/user.dart';
import 'domain/repository/auth.dart';
import 'domain/service/auth.dart';
import 'domain/service/notification.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'provider/drift/account.dart';
import 'provider/drift/background.dart';
import 'provider/drift/cache.dart';
import 'provider/drift/callkit_calls.dart';
import 'provider/drift/credentials.dart';
import 'provider/drift/download.dart';
import 'provider/drift/drift.dart';
import 'provider/drift/geolocation.dart';
import 'provider/drift/locks.dart';
import 'provider/drift/my_user.dart';
import 'provider/drift/secret.dart';
import 'provider/drift/settings.dart';
import 'provider/drift/skipped_version.dart';
import 'provider/drift/window.dart';
import 'provider/file/log.dart';
import 'provider/geo/geo.dart';
import 'provider/gql/graphql.dart';
import 'pubspec.g.dart';
import 'routes.dart';
import 'store/auth.dart';
import 'store/model/window_preferences.dart';
import 'themes.dart';
import 'ui/worker/age.dart';
import 'ui/worker/cache.dart';
import 'ui/worker/call.dart';
import 'ui/worker/log.dart';
import 'ui/worker/upgrade.dart';
import 'ui/worker/window.dart';
import 'util/backoff.dart';
import 'util/get.dart';
import 'util/log.dart';
import 'util/platform_utils.dart';
import 'util/web/web_utils.dart';

/// Entry point of this application.
Future<void> main() async {
  await runZonedGuarded(
    () async {
      final Stopwatch watch = Stopwatch()..start();

      await Config.init();

      me.Log.options = me.LogOptions(
        level: Config.logLevel,

        // Browsers collect timestamps for log themselves.
        timeStamp: !PlatformUtils.isWeb,
        dateStamp: !PlatformUtils.isWeb,
      );

      Log.maxLogs = Config.logAmount;

      // No need to initialize the Sentry if no DSN is provided, otherwise
      // useless messages are printed to the console every time the application
      // starts.
      if (Config.sentryDsn.isEmpty || kDebugMode) {
        return _runApp();
      }

      await SentryFlutter.init((options) {
        options.dsn = Config.sentryDsn;
        options.tracesSampleRate = 1.0;
        options.sampleRate = 1.0;
        options.release = '${Pubspec.name}@${Pubspec.ref}';
        options.diagnosticLevel = SentryLevel.info;
        options.enablePrintBreadcrumbs = true;
        options.maxBreadcrumbs = 512;
        options.enableTimeToFullDisplayTracing = true;
        options.enableAppHangTracking = true;
        options.enableLogs = true;
        options.beforeSend = (SentryEvent event, Hint? hint) {
          // Modules are meaningless in Flutter.
          event.modules = {};

          final SentryException? sentryException =
              event.exceptions?.firstOrNull;
          final dynamic exception = sentryException?.throwable;

          // Connection related exceptions shouldn't be logged.
          if (exception is Exception && exception.isNetworkRelated) {
            final Exception unreachable = UnreachableException();

            return SentryEvent(
              eventId: event.eventId,
              timestamp: event.timestamp,
              modules: event.modules,
              tags: event.tags,
              fingerprint: event.fingerprint,
              breadcrumbs: event.breadcrumbs,
              exceptions: [
                SentryException(
                  type: 'UnreachableException',
                  value: unreachable.toString(),
                  stackTrace: sentryException?.stackTrace,
                  mechanism: sentryException?.mechanism,
                  throwable: unreachable,
                ),
              ],
              threads: event.threads,
              sdk: event.sdk,
              platform: event.platform,
              logger: event.logger,
              serverName: event.serverName,
              release: event.release,
              dist: event.dist,
              environment: event.environment,
              message: event.message,
              transaction: event.transaction,
              throwable: event.throwable,
              level: event.level,
              culprit: event.culprit,
              user: event.user,
              contexts: event.contexts,
              request: event.request,
              debugMeta: event.debugMeta,
              type: event.type,
            );
          }

          // [Backoff] related exceptions shouldn't be logged.
          if (exception is OperationCanceledException ||
              exception.toString() == 'Data is not loaded') {
            return null;
          }

          return event;
        };
      });

      // Transaction indicating Flutter engine has rasterized the first frame.
      final ISentrySpan ready = Sentry.startTransaction(
        'ui.app.ready',
        'ui',
        autoFinishAfter: const Duration(minutes: 2),
        startTimestamp: DateTime.now().subtract(watch.elapsed),
      )..startChild('ready');

      WidgetsBinding.instance.waitUntilFirstFrameRasterized.then(
        (_) => ready.finish(),
      );

      await _runApp();
    },
    (error, stackTrace) {
      // If Sentry is enabled, then report the exception.
      if (Config.sentryDsn.isNotEmpty && !kDebugMode) {
        WebUtils.consoleError(
          'Uncaught (in promise) DartError: $error\n'
          '${stackTrace.toString().split('\n').where((e) => e.isNotEmpty).map((e) => '    at $e\n').join()}',
        );

        Sentry.captureException(error, stackTrace: stackTrace);
      }
      // Otherwise rethrow the exception to the parent `Zone`.
      else {
        Zone.root.handleUncaughtError(error, stackTrace);
      }
    },
  );
}

/// Initializes the dependencies and runs the [App].
Future<void> _runApp() async {
  WebUtils.registerWith();

  VideoPlayerMediaKit.ensureInitialized(
    android: false,
    web: false,

    // `AVPlayer` used by `video_player` does not support parsing URLs without
    // file extension in it.
    iOS: true,
    macOS: true,

    // `video_player` does not support neither Windows nor Linux.
    windows: true,
    linux: true,
  );

  JustAudioMediaKit.ensureInitialized(
    android: false,
    iOS: false,
    macOS: false,

    // `just_audio` doesn't support Linux.
    linux: true,

    // `just_audio` doesn't support Windows. And `just_audio_windows` seems to
    // crash under Windows in certain cases.
    windows: true,
  );

  WebUtils.setPathUrlStrategy();

  Get.putOrGet<CommonDriftProvider>(
    () => CommonDriftProvider.from(
      Get.putOrGet(() => CommonDatabase(), permanent: true),
    ),
    permanent: true,
  );

  final myUserProvider = Get.put(MyUserDriftProvider(Get.find()));
  Get.put(SettingsDriftProvider(Get.find()));
  Get.put(BackgroundDriftProvider(Get.find()));
  Get.put(GeoLocationDriftProvider(Get.find()));
  Get.put(LockDriftProvider(Get.find()));
  Get.put(RefreshSecretDriftProvider(Get.find()));
  Get.put(CallKitCallsDriftProvider(Get.find()));

  if (!PlatformUtils.isWeb) {
    Get.put(WindowRectDriftProvider(Get.find()));
    Get.put(CacheDriftProvider(Get.find()));
    Get.put(DownloadDriftProvider(Get.find()));
    Get.put(SkippedVersionDriftProvider(Get.find()));
    Get.put(LogFileProvider());
  }

  final accountProvider = Get.put(AccountDriftProvider(Get.find()));
  await accountProvider.init();

  final credentialsProvider = Get.put(CredentialsDriftProvider(Get.find()));
  await credentialsProvider.init();

  if (PlatformUtils.isDesktop && !PlatformUtils.isWeb) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(400, 400));

    final WindowRectDriftProvider? preferences =
        Get.findOrNull<WindowRectDriftProvider>();
    final WindowPreferences? prefs = await preferences?.read();

    if (prefs?.size != null) {
      await windowManager.setSize(prefs!.size!);
    }

    if (prefs?.position != null) {
      await windowManager.setPosition(prefs!.position!);
    }

    await windowManager.show();

    WebUtils.registerScheme().onError((_, _) => false);

    Get.put(WindowWorker(preferences));
  }

  final graphQlProvider = Get.put(GraphQlProvider());
  Get.put(GeoLocationProvider());

  final authRepository = Get.put<AbstractAuthRepository>(
    AuthRepository(graphQlProvider, myUserProvider, Get.find()),
  );
  final authService = Get.put(
    AuthService(authRepository, Get.find(), Get.find(), Get.find(), Get.find()),
  );

  Uri? initial;
  try {
    final AppLinks links = AppLinks();
    initial = await links.getInitialLink();
    Log.debug('initial -> $initial', 'AppLinks');

    _linkSubscription?.cancel();
    _linkSubscription = links.uriLinkStream.listen((uri) async {
      Log.debug('uriLinkStream -> $uri', 'AppLinks');
      router.delegate.setNewRoutePath(
        await router.parser.parseRouteInformation(RouteInformation(uri: uri)),
      );
    });
  } catch (e) {
    // No-op.
  }

  router = RouterState(
    authService,
    initial: initial == null ? null : RouteInformation(uri: initial),
  );

  try {
    PWAInstall().setup(
      installCallback: () {
        Log.debug('PWA is detected as installed', 'PWAInstall()');
        WebUtils.hasPwa = true;
      },
    );
  } catch (_) {
    // No-op.
  }

  await authService.init();
  await L10n.init();

  Get.put(
    CacheWorker(
      Get.findOrNull<CacheDriftProvider>(),
      Get.findOrNull<DownloadDriftProvider>(),
    ),
  );
  Get.put(UpgradeWorker(Get.findOrNull<SkippedVersionDriftProvider>()));
  Get.put(LogWorker(Get.findOrNull<LogFileProvider>()));
  Get.put(AgeWorker());

  WebUtils.deleteLoader();

  runApp(App(key: UniqueKey()));
}

/// Initializes the [FlutterCallkitIncoming] and displays an incoming call
/// notification, if the provided [message] is about a call.
///
/// Must be a top level function, as intended to be used as a Firebase Cloud
/// Messaging notification background handler.
@pragma('vm:entry-point')
Future<void> handlePushNotification(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // The code here should only be executed for Android devices, since other iOS
  // push notifications related code is handled either in `AppDelegate.swift` or
  // `NotificationService.swift` files due to iOS not giving guarantees about
  // calling this method.
  if (!PlatformUtils.isAndroid) {
    return;
  }

  Log.debug('handlePushNotification($message)', 'main');

  final String? tag = message.data['tag'] ?? message.notification?.android?.tag;
  final String? thread = message.data['thread'];

  final bool isCall =
      tag?.endsWith('_call') == true || tag?.endsWith('-call') == true;

  // Since tags are only working under Android, thus this code is related to
  // Android platform only - iOS doesn't execute that.
  if (isCall) {
    final ChatId chatId = ChatId(message.data['chatId']);

    SharedPreferences? prefs;
    CredentialsDriftProvider? credentialsProvider;
    AccountDriftProvider? accountProvider;
    GraphQlProvider? provider;
    StreamSubscription? subscription;

    try {
      FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
        switch (event!.event) {
          case Event.actionCallAccept:
            await prefs?.setString('answeredCall', chatId.val);
            break;

          case Event.actionCallDecline:
            await provider?.declineChatCall(chatId);
            break;

          case Event.actionCallEnded:
          case Event.actionCallTimeout:
            subscription?.cancel();
            provider?.disconnect();
            break;

          case Event.actionCallCallback:
            // TODO: Handle.
            break;

          default:
            break;
        }
      });

      // TODO: Use stored in [ApplicationSettings] language here.
      await L10n.init();

      await FlutterCallkitIncoming.showCallkitIncoming(
        CallKitParams(
          id: chatId.val,
          nameCaller: message.notification?.title ?? 'tapopa',
          appName: 'Tapopa',
          avatar: '', // TODO: Add avatar to FCM notifications.
          handle: chatId.val,
          type: 0,
          textAccept: 'btn_accept'.l10n,
          textDecline: 'btn_decline'.l10n,
          duration: 30000,
          extra: {'chatId': chatId.val},
          headers: {'platform': 'flutter'},
          android: AndroidParams(
            isCustomNotification: true,
            isShowLogo: false,
            ringtonePath: 'ringtone',
            backgroundColor: '#0955fa',
            backgroundUrl: '', // TODO: Add avatar to FCM notifications.
            actionColor: '#4CAF50',
            textColor: '#ffffff',
            incomingCallNotificationChannelName: 'label_incoming_call'.l10n,
            missedCallNotificationChannelName: 'label_chat_call_missed'.l10n,
            isShowCallID: true,
            isShowFullLockedScreen: true,
          ),
        ),
      );

      await Config.init();
      final common = CommonDriftProvider.from(CommonDatabase());
      credentialsProvider = CredentialsDriftProvider(common);
      accountProvider = AccountDriftProvider(common);

      await credentialsProvider.init();
      await accountProvider.init();

      final UserId? userId = accountProvider.userId;
      final Credentials? credentials = userId != null
          ? await credentialsProvider.read(userId)
          : null;

      if (credentials != null) {
        provider = GraphQlProvider();
        provider.token = credentials.access.secret;
        provider.reconnect();

        subscription = provider.chatEvents(chatId, null, () => null).listen((
          e,
        ) async {
          final events = ChatEvents$Subscription.fromJson(e.data!).chatEvents;
          if (events.$$typename == 'Chat') {
            final mixin = events as ChatEvents$Subscription$ChatEvents$Chat;
            final call = mixin.ongoingCall;

            if (call != null) {
              if (call.members.any((e) => e.user.id == credentials.userId)) {
                await FlutterCallkitIncoming.endCall(chatId.val.base62ToUuid());
              }
            }
          } else if (events.$$typename == 'ChatEventsVersioned') {
            final mixin =
                events
                    as ChatEvents$Subscription$ChatEvents$ChatEventsVersioned;

            for (var e in mixin.events) {
              if (e.$$typename == 'EventChatCallFinished') {
                await FlutterCallkitIncoming.endCall(chatId.val.base62ToUuid());
              } else if (e.$$typename == 'EventChatCallStarted') {
                final node =
                    e as ChatEventsVersionedMixin$Events$EventChatCallStarted;

                if (node.call.members.any(
                  (e) => e.user.id == credentials.userId,
                )) {
                  await FlutterCallkitIncoming.endCall(
                    chatId.val.base62ToUuid(),
                  );
                }
              } else if (e.$$typename == 'EventChatCallConversationStarted') {
                final node =
                    e
                        as ChatEventsVersionedMixin$Events$EventChatCallConversationStarted;

                if (node.call.members.any(
                  (e) => e.user.id == credentials.userId,
                )) {
                  await FlutterCallkitIncoming.endCall(
                    chatId.val.base62ToUuid(),
                  );
                }
              } else if (e.$$typename == 'EventChatCallAnswerTimeoutPassed') {
                var node =
                    e
                        as ChatEventsVersionedMixin$Events$EventChatCallAnswerTimeoutPassed;
                if (node.userId == credentials.userId) {
                  await FlutterCallkitIncoming.endCall(
                    chatId.val.base62ToUuid(),
                  );
                }
              } else if (e.$$typename == 'EventChatCallMemberJoined') {
                var node =
                    e as ChatEventsVersionedMixin$Events$EventChatCallMemberJoined;
                if (node.user.id == credentials.userId) {
                  await FlutterCallkitIncoming.endCall(
                    chatId.val.base62ToUuid(),
                  );
                }
              } else if (e.$$typename == 'EventChatCallMemberLeft') {
                var node =
                    e as ChatEventsVersionedMixin$Events$EventChatCallMemberLeft;
                if (node.user.id == credentials.userId) {
                  await FlutterCallkitIncoming.endCall(
                    chatId.val.base62ToUuid(),
                  );
                }
              } else if (e.$$typename == 'EventChatCallDeclined') {
                var node =
                    e as ChatEventsVersionedMixin$Events$EventChatCallDeclined;
                if (node.user.id == credentials.userId) {
                  await FlutterCallkitIncoming.endCall(
                    chatId.val.base62ToUuid(),
                  );
                }
              }
            }
          }
        });

        prefs = await SharedPreferences.getInstance();
        await prefs.remove('answeredCall');

        // Ensure that we haven't already joined the call.
        final query = await provider.getChat(chatId);
        final call = query.chat?.ongoingCall;
        if (call != null) {
          if (call.members.any((e) => e.user.id == credentials.userId)) {
            await FlutterCallkitIncoming.endCall(chatId.val.base62ToUuid());
          }
        }
      }

      // Remove the incoming call notification after a reasonable amount of
      // time for a better UX.
      await Future.delayed(30.seconds);

      await FlutterCallkitIncoming.endCall(chatId.val.base62ToUuid());
    } catch (_) {
      provider?.disconnect();
      subscription?.cancel();
      await FlutterCallkitIncoming.endCall(chatId.val.base62ToUuid());
    }

    return;
  }

  if (tag != null) {
    // There may be already an local notification, thus just cancel it before
    // displaying this new one.
    final plugin = FlutterLocalNotificationsPlugin();
    try {
      await plugin.cancel(tag.asHash, tag: tag);
    } catch (_) {
      // It's ok to fail.
    }
  }

  // If message contains no notification (it's a background notification),
  // then try canceling the notifications with the provided thread, if any, or
  // otherwise a single one, if data contains a tag.
  if (message.notification == null ||
      (message.notification?.title?.isEmpty != false &&
          message.notification?.body == null)) {
    await Future.delayed(Duration(milliseconds: 100), () async {
      final plugin = FlutterLocalNotificationsPlugin();

      if (thread != null) {
        for (var e in await plugin.getActiveNotifications()) {
          if (e.id != null && e.tag?.contains(thread) == true) {
            await plugin.cancel(e.id!, tag: e.tag);
          }
        }
      } else if (tag != null) {
        for (var e in await plugin.getActiveNotifications()) {
          if (e.id != null && e.tag == tag) {
            await plugin.cancel(e.id!, tag: e.tag);
          }
        }
      }
    });
  }

  // If payload contains a `ChatId` in it, then try sending a single
  // [GraphQlProvider.chatItems] query to mark the chat as delivered.
  {
    final String? chatId = thread ?? message.data['chatId'];

    if (chatId != null) {
      await Config.init();

      final common = CommonDriftProvider.from(CommonDatabase());
      final credentialsProvider = CredentialsDriftProvider(common);
      final accountProvider = AccountDriftProvider(common);

      await credentialsProvider.init();
      await accountProvider.init();

      final UserId? userId = accountProvider.userId;
      final Credentials? credentials = userId != null
          ? await credentialsProvider.read(userId)
          : null;

      if (credentials != null) {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false;

        provider.token = credentials.access.secret;

        try {
          await provider.chatItems(ChatId(chatId), first: 1);
        } catch (e) {
          // No-op.
        }

        provider.disconnect();
      }
    }
  }
}

/// Implementation of this application.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: MaterialApp.router(
        routerDelegate: router.delegate,
        routeInformationParser: router.parser,
        routeInformationProvider: router.provider,
        onGenerateTitle: (context) => 'Tapopa',
        theme: Themes.light(),
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// [AppLinks.uriLinkStream] subscription.
StreamSubscription? _linkSubscription;

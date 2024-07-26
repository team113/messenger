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

/// Mobile front-end part of social network project.
///
/// Application is currently under heavy development and may change drastically
/// between minor revisions.
library main;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:log_me/log_me.dart' as me;
import 'package:media_kit/media_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
// ignore: implementation_imports
import 'package:sentry_flutter/src/integrations/integrations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:window_manager/window_manager.dart';

import 'api/backend/schema.dart';
import 'config.dart';
import 'domain/model/chat.dart';
import 'domain/model/session.dart';
import 'domain/model/user.dart';
import 'domain/repository/auth.dart';
import 'domain/service/auth.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'provider/drift/account.dart';
import 'provider/drift/background.dart';
import 'provider/drift/cache.dart';
import 'provider/drift/credentials.dart';
import 'provider/drift/download.dart';
import 'provider/drift/drift.dart';
import 'provider/drift/my_user.dart';
import 'provider/drift/settings.dart';
import 'provider/drift/skipped_version.dart';
import 'provider/drift/window.dart';
import 'provider/gql/exceptions.dart';
import 'provider/gql/graphql.dart';
import 'pubspec.g.dart';
import 'routes.dart';
import 'store/auth.dart';
import 'store/model/window_preferences.dart';
import 'themes.dart';
import 'ui/worker/cache.dart';
import 'ui/worker/upgrade.dart';
import 'ui/worker/window.dart';
import 'util/android_utils.dart';
import 'util/backoff.dart';
import 'util/get.dart';
import 'util/ios_utils.dart';
import 'util/log.dart';
import 'util/platform_utils.dart';
import 'util/web/web_utils.dart';

/// Entry point of this application.
Future<void> main() async {
  final Stopwatch watch = Stopwatch()..start();

  await Config.init();

  me.Log.options = me.LogOptions(
    level: me.LogLevel.debug,

    // Browsers collect timestamps for log themselves.
    timeStamp: !PlatformUtils.isWeb,
    dateStamp: !PlatformUtils.isWeb,
  );

  // Initializes and runs the [App].
  Future<void> appRunner() async {
    MediaKit.ensureInitialized();
    WebUtils.setPathUrlStrategy();

    Get.put(
      CommonDriftProvider.from(
        Get.putOrGet(() => CommonDatabase(), permanent: true),
      ),
    );

    final myUserProvider = Get.put(MyUserDriftProvider(Get.find()));
    Get.put(SettingsDriftProvider(Get.find()));
    Get.put(BackgroundDriftProvider(Get.find()));

    if (!PlatformUtils.isWeb) {
      Get.put(WindowRectDriftProvider(Get.find()));
      Get.put(CacheDriftProvider(Get.find()));
      Get.put(DownloadDriftProvider(Get.find()));
      Get.put(SkippedVersionDriftProvider(Get.find()));
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

      WebUtils.registerScheme().onError((_, __) => false);

      Get.put(WindowWorker(preferences));
    }

    final graphQlProvider = Get.put(GraphQlProvider());

    final authRepository = Get.put<AbstractAuthRepository>(AuthRepository(
      graphQlProvider,
      myUserProvider,
      Get.find(),
    ));
    final authService = Get.put(
      AuthService(authRepository, Get.find(), Get.find()),
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

    await authService.init();
    await L10n.init();

    Get.put(CacheWorker(Get.findOrNull(), Get.findOrNull()));
    Get.put(UpgradeWorker(Get.findOrNull()));

    WebUtils.deleteLoader();

    runApp(
      DefaultAssetBundle(
        key: UniqueKey(),
        bundle: SentryAssetBundle(),
        child: const App(),
      ),
    );
  }

  // No need to initialize the Sentry if no DSN is provided, otherwise useless
  // messages are printed to the console every time the application starts.
  if (Config.sentryDsn.isEmpty || kDebugMode) {
    return appRunner();
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = Config.sentryDsn;
      options.tracesSampleRate = 1.0;
      options.sampleRate = 1.0;
      options.release = '${Pubspec.name}@${Pubspec.ref}';
      options.debug = true;
      options.diagnosticLevel = SentryLevel.info;
      options.enablePrintBreadcrumbs = true;
      options.maxBreadcrumbs = 512;
      options.enableTimeToFullDisplayTracing = true;
      options.enableAppHangTracking = true;
      options.enableTracing = true;
      options.beforeSend = (SentryEvent event, Hint? hint) {
        final exception = event.exceptions?.firstOrNull?.throwable;

        // Connection related exceptions shouldn't be logged.
        if (exception is ConnectionException ||
            exception is SocketException ||
            exception is WebSocketException ||
            exception is WebSocketChannelException ||
            exception is HttpException ||
            exception is ClientException ||
            exception is DioException ||
            exception is TimeoutException ||
            exception is ResubscriptionRequiredException) {
          return null;
        }

        // [Backoff] related exceptions shouldn't be logged.
        if (exception is OperationCanceledException ||
            exception.toString() == 'Data is not loaded') {
          return null;
        }

        return event;
      };
      options.logger = (
        SentryLevel level,
        String message, {
        String? logger,
        Object? exception,
        StackTrace? stackTrace,
      }) {
        if (exception != null) {
          if (stackTrace == null) {
            stackTrace = StackTrace.current;
          } else {
            stackTrace = FlutterError.demangleStackTrace(stackTrace);
          }

          final Iterable<String> lines =
              stackTrace.toString().trimRight().split('\n').take(100);

          Log.error(
            [
              exception.toString(),
              if (lines.where((e) => e.isNotEmpty).isNotEmpty)
                FlutterError.defaultStackFilter(lines).join('\n')
            ].join('\n'),
          );
        }
      };
    },
    appRunner: appRunner,
  );

  // TODO: Remove, when Sentry supports app start measurement for all platforms.
  // ignore: invalid_use_of_internal_member
  NativeAppStartIntegration.setAppStartInfo(
    AppStartInfo(
      AppStartType.cold,
      start: DateTime.now().subtract(watch.elapsed),
      pluginRegistration: DateTime.now().subtract(watch.elapsed),
      sentrySetupStart: DateTime.now().subtract(watch.elapsed),
      nativeSpanTimes: [],
      end: DateTime.now(),
    ),
  );

  // Transaction indicating Flutter engine has rasterized the first frame.
  final ISentrySpan ready = Sentry.startTransaction(
    'ui.app.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
    startTimestamp: DateTime.now().subtract(watch.elapsed),
  )..startChild('ready');

  WidgetsBinding.instance.waitUntilFirstFrameRasterized
      .then((_) => ready.finish());
}

/// Initializes the [FlutterCallkitIncoming] and displays an incoming call
/// notification, if the provided [message] is about a call.
///
/// Must be a top level function, as intended to be used as a Firebase Cloud
/// Messaging notification background handler.
@pragma('vm:entry-point')
Future<void> handlePushNotification(RemoteMessage message) async {
  Log.debug('handlePushNotification($message)', 'main');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (message.notification?.android?.tag?.endsWith('_call') == true &&
      message.data['chatId'] != null) {
    SharedPreferences? prefs;
    CredentialsDriftProvider? credentialsProvider;
    AccountDriftProvider? accountProvider;
    GraphQlProvider? provider;
    StreamSubscription? subscription;

    try {
      FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
        switch (event!.event) {
          case Event.actionCallAccept:
            await prefs?.setString('answeredCall', message.data['chatId']);
            break;

          case Event.actionCallDecline:
            await provider?.declineChatCall(ChatId(message.data['chatId']));
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
          id: message.data['chatId'],
          nameCaller: message.notification?.title ?? 'gapopa',
          appName: 'Gapopa',
          avatar: '', // TODO: Add avatar to FCM notifications.
          handle: message.data['chatId'],
          type: 0,
          textAccept: 'btn_accept'.l10n,
          textDecline: 'btn_decline'.l10n,
          duration: 30000,
          extra: {'chatId': message.data['chatId']},
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
      final Credentials? credentials =
          userId != null ? await credentialsProvider.read(userId) : null;

      if (credentials != null) {
        provider = GraphQlProvider();
        provider.token = credentials.access.secret;
        provider.reconnect();

        subscription = provider
            .chatEvents(ChatId(message.data['chatId']), null, () => null)
            .listen((e) async {
          var events = ChatEvents$Subscription.fromJson(e.data!).chatEvents;
          if (events.$$typename == 'ChatEventsVersioned') {
            var mixin = events
                as ChatEvents$Subscription$ChatEvents$ChatEventsVersioned;

            for (var e in mixin.events) {
              if (e.$$typename == 'EventChatCallFinished') {
                await FlutterCallkitIncoming.endCall(message.data['chatId']);
              } else if (e.$$typename == 'EventChatCallMemberJoined') {
                var node = e
                    as ChatEventsVersionedMixin$Events$EventChatCallMemberJoined;
                if (node.user.id == credentials.userId) {
                  await FlutterCallkitIncoming.endCall(message.data['chatId']);
                }
              } else if (e.$$typename == 'EventChatCallDeclined') {
                var node =
                    e as ChatEventsVersionedMixin$Events$EventChatCallDeclined;
                if (node.user.id == credentials.userId) {
                  await FlutterCallkitIncoming.endCall(message.data['chatId']);
                }
              }
            }
          }
        });

        prefs = await SharedPreferences.getInstance();
        await prefs.remove('answeredCall');
      }

      // Remove the incoming call notification after a reasonable amount of
      // time for a better UX.
      await Future.delayed(30.seconds);

      await FlutterCallkitIncoming.endCall(message.data['chatId']);
    } catch (_) {
      provider?.disconnect();
      subscription?.cancel();
      await FlutterCallkitIncoming.endCall(message.data['chatId']);
    }
  } else {
    // If message contains no notification (it's a background notification),
    // then try canceling the notifications with the provided thread, if any, or
    // otherwise a single one, if data contains a tag.
    if (message.notification == null) {
      final String? tag = message.data['tag'];
      final String? thread = message.data['thread'];

      if (PlatformUtils.isAndroid) {
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
    }

    // If payload contains a `ChatId` in it, then try sending a single
    // [GraphQlProvider.chatItems] query to mark the chat as delivered.
    //
    // Note, that on iOS this behaviour is done via separate Notification
    // Service Extension, as this code isn't guaranteed to be invoked at all,
    // especially for visual notifications.
    if (PlatformUtils.isAndroid) {
      final String? chatId = message.data['chatId'];

      if (chatId != null) {
        await Config.init();

        final common = CommonDriftProvider.from(CommonDatabase());
        final credentialsProvider = CredentialsDriftProvider(common);
        final accountProvider = AccountDriftProvider(common);

        await credentialsProvider.init();
        await accountProvider.init();

        final UserId? userId = accountProvider.userId;
        final Credentials? credentials =
            userId != null ? await credentialsProvider.read(userId) : null;

        if (credentials != null) {
          final provider = GraphQlProvider();
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
}

/// Implementation of this application.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1)),
      child: GetMaterialApp.router(
        routerDelegate: router.delegate,
        routeInformationParser: router.parser,
        routeInformationProvider: router.provider,
        onGenerateTitle: (context) => 'Gapopa',
        theme: Themes.light(),
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// [AppLinks.uriLinkStream] subscription.
StreamSubscription? _linkSubscription;

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

import 'package:callkeep/callkeep.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:log_me/log_me.dart' as me;
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:window_manager/window_manager.dart';

import 'api/backend/schema.dart';
import 'config.dart';
import 'domain/model/chat.dart';
import 'domain/model/session.dart';
import 'domain/repository/auth.dart';
import 'domain/service/auth.dart';
import 'l10n/l10n.dart';
import 'provider/gql/exceptions.dart';
import 'provider/gql/graphql.dart';
import 'provider/hive/cache.dart';
import 'provider/hive/credentials.dart';
import 'provider/hive/download.dart';
import 'provider/hive/window.dart';
import 'pubspec.g.dart';
import 'routes.dart';
import 'store/auth.dart';
import 'store/model/window_preferences.dart';
import 'themes.dart';
import 'ui/worker/cache.dart';
import 'ui/worker/window.dart';
import 'util/backoff.dart';
import 'util/log.dart';
import 'util/platform_utils.dart';
import 'util/web/web_utils.dart';

/// Entry point of this application.
Future<void> main() async {
  await Config.init();

  me.Log.options = me.LogOptions(
    level: Config.logLevel,

    // Browsers collect timestamps for log themselves.
    timeStamp: !PlatformUtils.isWeb,
    dateStamp: !PlatformUtils.isWeb,
  );

  // Initializes and runs the [App].
  Future<void> appRunner() async {
    MediaKit.ensureInitialized();
    WebUtils.setPathUrlStrategy();

    await _initHive();

    if (PlatformUtils.isDesktop && !PlatformUtils.isWeb) {
      await windowManager.ensureInitialized();
      await windowManager.setMinimumSize(const Size(400, 400));

      final WindowPreferencesHiveProvider preferences = Get.find();
      final WindowPreferences? prefs = preferences.get();

      if (prefs?.size != null) {
        await windowManager.setSize(prefs!.size!);
      }

      if (prefs?.position != null) {
        await windowManager.setPosition(prefs!.position!);
      }

      await windowManager.show();

      Get.put(WindowWorker(preferences));
    }

    final graphQlProvider = Get.put(GraphQlProvider());

    Get.put<AbstractAuthRepository>(AuthRepository(graphQlProvider));
    final authService =
        Get.put(AuthService(AuthRepository(graphQlProvider), Get.find()));
    router = RouterState(authService);

    authService.init();
    await L10n.init();

    Get.put(CacheWorker(Get.findOrNull(), Get.findOrNull()));

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
      options.release =
          '${Pubspec.name}@${Pubspec.ref ?? Config.version ?? Pubspec.version}';
      options.debug = true;
      options.diagnosticLevel = SentryLevel.info;
      options.enablePrintBreadcrumbs = true;
      options.maxBreadcrumbs = 512;
      options.beforeSend = (SentryEvent event, {Hint? hint}) {
        final exception = event.exceptions?.firstOrNull?.throwable;

        // Connection related exceptions shouldn't be logged.
        if (exception is ConnectionException ||
            exception is SocketException ||
            exception is WebSocketException ||
            exception is WebSocketChannelException ||
            exception is HttpException ||
            exception is ClientException ||
            exception is DioException ||
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
}

/// Initializes the [FlutterCallkeep] and displays an incoming call
/// notification, if the provided [message] is about a call.
///
/// Must be a top level function, as intended to be used as a Firebase Cloud
/// Messaging notification background handler.
@pragma('vm:entry-point')
Future<void> handlePushNotification(RemoteMessage message) async {
  Log.debug('handlePushNotification($message)', 'main');

  if (message.notification?.android?.tag?.endsWith('_call') == true &&
      message.data['chatId'] != null) {
    final FlutterCallkeep callKeep = FlutterCallkeep();

    if (await callKeep.hasPhoneAccount()) {
      SharedPreferences? prefs;
      CredentialsHiveProvider? credentialsProvider;
      GraphQlProvider? provider;
      StreamSubscription? subscription;

      try {
        await callKeep.setup(
          null,
          Config.callKeep,
          backgroundMode: true,
        );

        callKeep.on(
          CallKeepPerformAnswerCallAction(),
          (CallKeepPerformAnswerCallAction event) async {
            await prefs?.setString('answeredCall', message.data['chatId']);
            await callKeep.rejectCall(event.callUUID!);
            await callKeep.backToForeground();
          },
        );

        callKeep.on(
          CallKeepPerformEndCallAction(),
          (CallKeepPerformEndCallAction event) async {
            if (prefs?.getString('answeredCall') != event.callUUID!) {
              await provider?.declineChatCall(ChatId(event.callUUID!));
            }

            subscription?.cancel();
            provider?.disconnect();
            await Hive.close();
          },
        );

        callKeep.displayIncomingCall(
          message.data['chatId'],
          message.notification?.title ?? 'gapopa',
          handleType: 'generic',
        );

        await Config.init();
        await Hive.initFlutter('hive');
        credentialsProvider = CredentialsHiveProvider();

        await credentialsProvider.init();
        final Credentials? credentials = credentialsProvider.get();
        await credentialsProvider.close();

        if (credentials != null) {
          provider = GraphQlProvider();
          provider.token = credentials.session.token;
          provider.reconnect();

          subscription = provider
              .chatEvents(ChatId(message.data['chatId']), null, () => null)
              .listen((e) {
            var events = ChatEvents$Subscription.fromJson(e.data!).chatEvents;
            if (events.$$typename == 'ChatEventsVersioned') {
              var mixin = events
                  as ChatEvents$Subscription$ChatEvents$ChatEventsVersioned;

              for (var e in mixin.events) {
                if (e.$$typename == 'EventChatCallFinished') {
                  callKeep.rejectCall(message.data['chatId']);
                } else if (e.$$typename == 'EventChatCallMemberJoined') {
                  var node = e
                      as ChatEventsVersionedMixin$Events$EventChatCallMemberJoined;
                  if (node.user.id == credentials.userId) {
                    callKeep.rejectCall(message.data['chatId']);
                  }
                } else if (e.$$typename == 'EventChatCallDeclined') {
                  var node = e
                      as ChatEventsVersionedMixin$Events$EventChatCallDeclined;
                  if (node.user.id == credentials.userId) {
                    callKeep.rejectCall(message.data['chatId']);
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

        callKeep.rejectCall(message.data['chatId']);
      } catch (_) {
        provider?.disconnect();
        subscription?.cancel();
        callKeep.rejectCall(message.data['chatId']);
        await credentialsProvider?.close();
        await Hive.close();
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

/// Initializes a [Hive] storage and registers a [CredentialsHiveProvider] in
/// the [Get]'s context.
Future<void> _initHive() async {
  await Hive.initFlutter('hive');

  // Load and compare application version.
  final Box box = await Hive.openBox('version');

  final String version = Config.version ?? Config.schema ?? Pubspec.version;
  final String? storedVersion = box.get(0);

  final String? session = Config.version ?? Config.credentials;
  final String? storedSession = box.get(1);

  // If mismatch is detected, then clean the existing [Hive] cache.
  if (storedVersion != version || storedSession != session) {
    await Hive.close();
    await Hive.clean(
      'hive',
      except: storedSession != session ? null : 'credentials',
    );
    await Hive.initFlutter('hive');
    Hive.openBox('version').then((box) async {
      await box.put(0, version);

      if (session != null) {
        await box.put(1, session);
      } else if (storedSession != null) {
        await box.delete(1);
      }

      await box.close();
    });
  }

  await Get.put(CredentialsHiveProvider()).init();
  await Get.put(WindowPreferencesHiveProvider()).init();

  if (!PlatformUtils.isWeb) {
    await Get.put(CacheInfoHiveProvider()).init();
    await Get.put(DownloadHiveProvider()).init();
  }
}

/// Extension adding an ability to clean [Hive].
extension HiveClean on HiveInterface {
  /// Cleans the [Hive] data stored at the provided [path] on non-web platforms
  /// and the whole `IndexedDB` on a web platform.
  Future<void> clean(String path, {String? except}) async {
    if (PlatformUtils.isWeb) {
      await WebUtils.cleanIndexedDb(except: except);
    } else {
      final String documents = (await getApplicationDocumentsDirectory()).path;
      final Directory directory = Directory('$documents/$path');

      try {
        if (except == null) {
          await directory.delete(recursive: true);
        } else {
          for (var file in directory.listSync()) {
            if (!file.path.endsWith('$except.hive') &&
                !file.path.endsWith('$except.lock')) {
              await file.delete();
            }
          }
        }
      } on FileSystemException {
        // No-op.
      }
    }
  }
}

/// Extension adding ability to find non-strict dependencies from a
/// [GetInterface].
extension on GetInterface {
  /// Returns the [S] dependency, if it [isRegistered].
  S? findOrNull<S>({String? tag}) {
    if (isRegistered<S>(tag: tag)) {
      return find<S>(tag: tag);
    }

    return null;
  }
}

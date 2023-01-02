// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_io/io.dart';
import 'package:window_manager/window_manager.dart';

import 'config.dart';
import 'domain/repository/auth.dart';
import 'domain/service/auth.dart';
import 'l10n/l10n.dart';
import 'provider/gql/graphql.dart';
import 'provider/hive/session.dart';
import 'provider/hive/window.dart';
import 'pubspec.g.dart';
import 'routes.dart';
import 'store/auth.dart';
import 'store/model/window_preferences.dart';
import 'themes.dart';
import 'ui/worker/background/background.dart';
import 'ui/worker/window.dart';
import 'util/log.dart';
import 'util/platform_utils.dart';
import 'util/web/web_utils.dart';

/// Entry point of this application.
Future<void> main() async {
  await Config.init();

  // Initializes and runs the [App].
  Future<void> appRunner() async {
    WebUtils.setPathUrlStrategy();

    await _initHive();

    if (PlatformUtils.isDesktop && !PlatformUtils.isWeb) {
      await windowManager.ensureInitialized();

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

    await authService.init();
    await L10n.init();

    Get.put(BackgroundWorker(Get.find()));

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

  return SentryFlutter.init(
    (options) => {
      options.dsn = Config.sentryDsn,
      options.tracesSampleRate = 1.0,
      options.release = '${Pubspec.name}@${Pubspec.version}',
      options.debug = true,
      options.diagnosticLevel = SentryLevel.info,
      options.enablePrintBreadcrumbs = true,
      options.integrations.add(OnErrorIntegration()),
      options.logger = (
        SentryLevel level,
        String message, {
        String? logger,
        Object? exception,
        StackTrace? stackTrace,
      }) {
        if (exception != null) {
          StringBuffer buf = StringBuffer('$exception');
          if (stackTrace != null) {
            buf.write(
                '\n\nWhen the exception was thrown, this was the stack:\n');
            buf.write(stackTrace.toString().replaceAll('\n', '\t\n'));
          }

          Log.error(buf.toString());
        }
      },
    },
    appRunner: appRunner,
  );
}

/// Implementation of this application.
class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      routerDelegate: router.delegate,
      routeInformationParser: router.parser,
      routeInformationProvider: router.provider,
      navigatorObservers: [SentryNavigatorObserver()],
      onGenerateTitle: (context) => 'Gapopa',
      theme: Themes.light(),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Initializes a [Hive] storage and registers a [SessionDataHiveProvider] in
/// the [Get]'s context.
Future<void> _initHive() async {
  await Hive.initFlutter('hive');

  // Load and compare application version.
  Box box = await Hive.openBox('version');
  String version = Pubspec.version;
  String? stored = box.get(0);

  // If mismatch is detected, then clean the existing [Hive] cache.
  if (stored != version) {
    await Hive.close();
    await Hive.clean('hive');
    await Hive.initFlutter('hive');
    Hive.openBox('version').then((box) async {
      await box.put(0, version);
      await box.close();
    });
  }

  await Get.put(SessionDataHiveProvider()).init();
  await Get.put(WindowPreferencesHiveProvider()).init();
}

/// Extension adding an ability to clean [Hive].
extension HiveClean on HiveInterface {
  /// Cleans the [Hive] data stored at the provided [path] on non-web platforms
  /// and the whole `IndexedDB` on a web platform.
  Future<void> clean(String path) async {
    if (PlatformUtils.isWeb) {
      await WebUtils.cleanIndexedDb();
    } else {
      var documents = (await getApplicationDocumentsDirectory()).path;
      try {
        await Directory('$documents/$path').delete(recursive: true);
      } on FileSystemException {
        // No-op.
      }
    }
  }
}

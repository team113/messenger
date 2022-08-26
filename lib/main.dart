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

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show NotificationResponse;
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:multi_window/multi_window.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

import 'pubspec.g.dart';
import 'themes.dart';

/// Entry point of this application.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MultiWindow.init(args);

  //await windowManager.ensureInitialized();

  runApp(
    const _ExampleSubWindow(),
  );

  // Initializes and runs the [App].
  // Future<void> _appRunner() async {
  //   WebUtils.setPathUrlStrategy();
  //   if (PlatformUtils.isDesktop && !PlatformUtils.isWeb) {
  //     await windowManager.ensureInitialized();
  //   }
  //
  //   await _initHive();
  //
  //   Get.put(NotificationService())
  //       .init(onNotificationResponse: onNotificationResponse);
  //
  //   var graphQlProvider = Get.put(GraphQlProvider());
  //
  //   Get.put<AbstractAuthRepository>(AuthRepository(graphQlProvider));
  //   var authService =
  //       Get.put(AuthService(AuthRepository(graphQlProvider), Get.find()));
  //   await authService.init();
  //
  //   await L10n.init();
  //
  //   router = RouterState(authService);
  //
  //   Get.put(BackgroundWorker(Get.find()));
  //
  //   runApp(
  //     DefaultAssetBundle(
  //       key: UniqueKey(),
  //       bundle: SentryAssetBundle(),
  //       child: const App(),
  //     ),
  //   );
  //   //}
  // }
  //
  // // No need to initialize the Sentry if no DSN is provided, otherwise useless
  // // messages are printed to the console every time the application starts.
  // if (Config.sentryDsn.isEmpty || kDebugMode) {
  //   return _appRunner();
  // }
  //
  // return SentryFlutter.init(
  //   (options) => {
  //     options.dsn = Config.sentryDsn,
  //     options.tracesSampleRate = 1.0,
  //     options.release = '${Pubspec.name}@${Pubspec.version}',
  //     options.debug = true,
  //     options.diagnosticLevel = SentryLevel.info,
  //     options.enablePrintBreadcrumbs = true,
  //     options.logger = (
  //       SentryLevel level,
  //       String message, {
  //       String? logger,
  //       Object? exception,
  //       StackTrace? stackTrace,
  //     }) {
  //       if (exception != null) {
  //         StringBuffer buf = StringBuffer('$exception');
  //         if (stackTrace != null) {
  //           buf.write(
  //               '\n\nWhen the exception was thrown, this was the stack:\n');
  //           buf.write(stackTrace.toString().replaceAll('\n', '\t\n'));
  //         }
  //
  //         Log.error(buf.toString());
  //       }
  //     },
  //   },
  //   appRunner: _appRunner,
  // );
}

class _ExampleSubWindow extends StatelessWidget {
  const _ExampleSubWindow({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            const Text(
              'Arguments',
              style: TextStyle(fontSize: 20),
            ),
            TextButton(
              onPressed: () async {
                // var desktopWindow = await DesktopMultiWindow.createWindow('');
                // desktopWindow
                //   ..setFrame(const Offset(0, 0) & const Size(700, 700))
                //   ..center()
                //   ..setTitle('Call')
                //   ..show();
                await MultiWindow.create('window_id');
              },
              child: const Text('Open window'),
            ),
          ],
        ),
      ),
    );
  }
}

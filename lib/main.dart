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
import 'package:flutter/material.dart';
import 'package:multi_window/multi_window.dart';
import 'package:window_manager/window_manager.dart';

/// Entry point of this application.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MultiWindow.init(args);

  await windowManager.ensureInitialized();

  runApp(
    const _ExampleSubWindow(),
  );
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
                var desktopWindow = await DesktopMultiWindow.createWindow('');
                desktopWindow
                  ..setFrame(const Offset(0, 0) & const Size(700, 700))
                  ..center()
                  ..setTitle('Call')
                  ..show();
                // var window = await MultiWindow.create('window_id');
              },
              child: const Text('Open window'),
            ),
          ],
        ),
      ),
    );
  }
}

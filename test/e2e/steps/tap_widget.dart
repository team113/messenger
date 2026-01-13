// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
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

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/util/log.dart';

import '../configuration.dart';
import '../parameters/keys.dart';
import '../world/custom_world.dart';

/// Taps the widget found with the given [WidgetKey].
///
/// Examples:
/// - When I tap `WidgetKey` button
/// - When I tap `WidgetKey` element
/// - When I tap `WidgetKey` label
/// - When I tap `WidgetKey` icon
/// - When I tap `WidgetKey` field
/// - When I tap `WidgetKey` text
/// - When I tap `WidgetKey` widget
final StepDefinitionGeneric tapWidget = when1<WidgetKey, CustomWorld>(
  RegExp(r'I tap {key} (?:button|element|label|icon|field|text|widget)$'),
  (key, context) async {
    Log.debug(
      'tapWidget($key) -> await context.world.appDriver.waitUntil()...',
      'E2E',
    );

    await context.world.appDriver.waitUntil(() async {
      Log.debug('tapWidget($key) -> await waitForAppToSettle()...', 'E2E');

      await context.world.appDriver.nativeDriver.pump(
        const Duration(seconds: 2),
        EnginePhase.composite,
      );

      Log.debug(
        'tapWidget($key) -> await waitForAppToSettle()... done!',
        'E2E',
      );

      try {
        final finder = context.world.appDriver
            .findByKeySkipOffstage(key.name)
            .first;

        Log.debug('tapWidget($key) -> finder is: $finder', 'E2E');

        await context.world.appDriver.nativeDriver.tap(
          finder,
          kind: PointerDeviceKind.mouse,
        );

        Log.debug(
          'tapWidget($key) -> await context.world.appDriver.tap()... done!',
          'E2E',
        );

        return true;
      } catch (e) {
        Log.debug('tapWidget($key) -> caught exception: $e', 'E2E');
      }

      return false;
    }, timeout: const Duration(seconds: 60));

    Log.debug(
      'tapWidget($key) -> await context.world.appDriver.waitUntil()... done!',
      'E2E',
    );
  },
);

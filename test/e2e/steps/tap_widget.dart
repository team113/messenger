// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';

import '../configuration.dart';
import '../parameters/keys.dart';

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
final StepDefinitionGeneric tapWidget = when1<WidgetKey, FlutterWorld>(
  RegExp(r'I tap {key} (?:button|element|label|icon|field|text|widget)$'),
  (key, context) async {
    print('======0 tapWidget(${key.name}) -> started');

    await context.world.appDriver.waitUntil(() async {
      print('======0 tapWidget(${key.name}) -> waitForAppToSettle0...');
      await context.world.appDriver.waitForAppToSettle();
      print('======0 tapWidget(${key.name}) -> waitForAppToSettle0... done');

      try {
        final finder =
            context.world.appDriver.findByKeySkipOffstage(key.name).first;
        print('======0 tapWidget(${key.name}) -> finder: $finder');

        await context.world.appDriver.waitForAppToSettle();
        print('======0 tapWidget(${key.name}) -> waitForAppToSettle1... done');

        print('======0 tapWidget(${key.name}) -> tap...');
        await context.world.appDriver.tap(
          finder,
          timeout: context.configuration.timeout,
        );
        print('======0 tapWidget(${key.name}) -> tap... done');

        await context.world.appDriver.waitForAppToSettle();
        print('======0 tapWidget(${key.name}) -> waitForAppToSettle2... done');

        print('======0 tapWidget(${key.name}) -> return true');
        return true;
      } catch (e) {
        print('======0 tapWidget(${key.name}) -> caught $e');
        // No-op.
      }

      print('======0 tapWidget(${key.name}) -> return false');
      return false;
    }, timeout: const Duration(seconds: 30));

    print('======0 tapWidget(${key.name}) -> ended');
  },
);

// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

/// Taps the widget found with the given [WidgetKey] the provided times.
///
/// Examples:
/// - When I tap `WidgetKey` button 10 times
/// - When I tap `WidgetKey` element 10 times
/// - When I tap `WidgetKey` label 10 times
/// - When I tap `WidgetKey` icon 10 times
/// - When I tap `WidgetKey` field 10 times
/// - When I tap `WidgetKey` text 10 times
/// - When I tap `WidgetKey` widget 10 times
final StepDefinitionGeneric
tapWidgetNTimes = when2<WidgetKey, int, FlutterWorld>(
  RegExp(
    r'I tap {key} (?:button|element|label|icon|field|text|widget) {int} times$',
  ),
  (key, count, context) async {
    for (var i = 0; i < count; ++i) {
      await context.world.appDriver.waitUntil(() async {
        await context.world.appDriver.waitForAppToSettle();

        try {
          final finder = context.world.appDriver
              .findByKeySkipOffstage(key.name)
              .first;

          await context.world.appDriver.waitForAppToSettle();
          await context.world.appDriver.tap(
            finder,
            timeout: context.configuration.timeout,
          );
          await context.world.appDriver.waitForAppToSettle();

          return true;
        } catch (_) {
          // No-op.
        }

        return false;
      }, timeout: const Duration(seconds: 30));
    }
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

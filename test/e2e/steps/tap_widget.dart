// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/widgets.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/routes.dart';

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
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      try {
        final finder =
            context.world.appDriver.findByKeySkipOffstage(key.name).first;

        if (await context.world.appDriver.isPresent(finder)) {
          Offset? position =
              (finder.evaluate().first.renderObject as RenderBox?)
                  ?.localToGlobal(Offset.zero);

          if ((position?.dy ?? 0) + 200 >
              MediaQuery.of(router.context!).size.height) {
            await context.world.appDriver.scrollIntoView(finder);
          }

          await context.world.appDriver.waitForAppToSettle();
          await context.world.appDriver.tap(
            finder,
            timeout: context.configuration.timeout,
          );
          await context.world.appDriver.waitForAppToSettle();
          return true;
        }
      } catch (_) {
        //No-op.
      }

      return false;
    }, timeout: const Duration(seconds: 20));
  },
);

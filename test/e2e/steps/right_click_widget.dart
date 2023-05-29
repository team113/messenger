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

import 'package:flutter/gestures.dart';
import 'package:gherkin/gherkin.dart';

import '../configuration.dart';
import '../parameters/keys.dart';
import '../world/custom_world.dart';

/// Right clicks the widget found with the given [WidgetKey].
///
/// Examples:
/// - When I right click `WidgetKey` button
/// - When I right click `WidgetKey` element
/// - When I right click `WidgetKey` label
/// - When I right click `WidgetKey` icon
/// - When I right click `WidgetKey` field
/// - When I right click `WidgetKey` text
/// - When I right click `WidgetKey` widget
final StepDefinitionGeneric rightClickWidget = when1<WidgetKey, CustomWorld>(
  RegExp(r'I right click {key} (?:button|element|label|icon|field|text|widget)$'),
      (key, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      try {
        final finder =
            context.world.appDriver.findByKeySkipOffstage(key.name).first;

        await context.world.appDriver.waitForAppToSettle();
        await context.world.appDriver.nativeDriver.tap(
          finder,
          buttons: kSecondaryMouseButton,
        );
        await context.world.appDriver.waitForAppToSettle();
        return true;
      } catch (_) {
        // No-op.
      }

      return false;
    }, timeout: const Duration(seconds: 20));
  },
);

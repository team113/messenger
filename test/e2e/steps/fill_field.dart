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

import 'package:flutter/material.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';

import '../parameters/keys.dart';

/// Enters the given text into the widget with the provided [WidgetKey].
///
/// Examples:
/// - Then I fill `EmailField` field with "bob@gmail.com"
/// - Then I fill `NameField` field with "Woody Johnson"
StepDefinitionGeneric fillField = when2<WidgetKey, String, FlutterWorld>(
  'I fill {key} field with {string}',
  (key, value, context) async {
    await context.world.appDriver.waitForAppToSettle();
    final finder = context.world.appDriver.findBy(key.name, FindType.key);

    await context.world.appDriver.scrollIntoView(finder);
    await context.world.appDriver.waitForAppToSettle();
    await context.world.appDriver.tap(
      finder,
      timeout: context.configuration.timeout,
    );
    await context.world.appDriver.waitForAppToSettle();

    final finder2 = context.world.appDriver.findBy(key.name, FindType.key);
    await context.world.appDriver.scrollIntoView(finder2);
    await context.world.appDriver.enterText(finder2, value);

    await context.world.appDriver.waitForAppToSettle();

    FocusManager.instance.primaryFocus?.unfocus();
  },
);

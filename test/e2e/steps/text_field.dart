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
import 'package:messenger/ui/page/home/page/my_profile/widget/copyable.dart';
import 'package:messenger/ui/widget/text_field.dart';

import '../parameters/keys.dart';
import '../world/custom_world.dart';

/// Enters the given text into the widget with the provided [WidgetKey].
///
/// Examples:
/// - Then I fill `EmailField` field with "bob@gmail.com"
/// - Then I fill `NameField` field with "Woody Johnson"
StepDefinitionGeneric fillField = when2<WidgetKey, String, FlutterWorld>(
  'I fill {key} field with {string}',
  fillTextField,
);

/// Enters the [CustomWorld.clipboardValue] text into the widget with the
/// provided [WidgetKey].
StepDefinitionGeneric fillFieldFromClipboard = when1<WidgetKey, CustomWorld>(
  'I fill {key} field with clipboard value',
  (key, context) async {
    if (context.world.clipboardValue != null) {
      await fillTextField(key, context.world.clipboardValue!, context);
    }
  },
);

/// Saves the value from the textfield to [CustomWorld.clipboardValue].
StepDefinitionGeneric saveFieldTextToClipboard = when1<WidgetKey, CustomWorld>(
  'I save value of {key} field to clipboard',
  (key, context) async {
    await context.world.appDriver.waitForAppToSettle();
    final finder = context.world.appDriver.findBy(key.name, FindType.key);

    await context.world.appDriver.scrollIntoView(finder);
    await context.world.appDriver.waitForAppToSettle();

    Widget textFieldWidget = finder.evaluate().single.widget;

    String? text;

    switch (textFieldWidget.runtimeType) {
      case ReactiveTextField:
        text = (textFieldWidget as ReactiveTextField).state.controller.text;
        break;
      case CopyableTextField:
        text = (textFieldWidget as CopyableTextField).copy;
        break;
      default:
        break;
    }

    if (text != null) {
      context.world.clipboardValue = text;
    }
  },
);

/// Function for the entering of the [value] text into the widget with the
/// provided [WidgetKey].
Future<void> fillTextField(
    WidgetKey key, String value, StepContext<FlutterWorld> context) async {
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
}

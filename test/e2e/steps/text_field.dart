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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ClipboardData;
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/copyable.dart';
import 'package:messenger/ui/page/home/widget/num.dart';
import 'package:messenger/ui/widget/text_field.dart';

import '../configuration.dart';
import '../parameters/keys.dart';
import '../world/custom_world.dart';

/// Enters the given text into the widget with the provided [WidgetKey].
///
/// Examples:
/// - Then I fill `EmailField` field with "bob@gmail.com"
/// - Then I fill `NameField` field with "Woody Johnson"
StepDefinitionGeneric fillField = when2<WidgetKey, String, FlutterWorld>(
  'I fill {key} field with {string}',
  _fillField,
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 30),
);

/// Enters the given text into the widget with the provided [WidgetKey].
///
/// Examples:
/// - Then I fill `MessageField` field with 8192 "A" symbols
StepDefinitionGeneric fillFieldN = when3<WidgetKey, int, String, FlutterWorld>(
  'I fill {key} field with {int} {string} symbol(s)?',
  (key, quantity, text, context) => _fillField(key, text * quantity, context),
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 30),
);

/// Pastes the [CustomWorld.clipboard] into the widget with the provided
/// [WidgetKey].
///
/// Examples:
/// - Then I paste to `EmailField` field
StepDefinitionGeneric pasteToField = when1<WidgetKey, CustomWorld>(
  'I paste to {key} field',
  (key, context) async {
    if (context.world.clipboard?.text == null) {
      throw ArgumentError('Nothing to fill, clipboard contains no text.');
    }

    await _fillField(key, context.world.clipboard!.text!, context);
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 30),
);

/// Copies the value of the widget with the provided [WidgetKey] to the
/// [CustomWorld.clipboard].
///
/// Examples:
/// - Then I copy from `EmailField` field
StepDefinitionGeneric copyFromField = when1<WidgetKey, CustomWorld>(
  'I copy from {key} field',
  (key, context) async {
    await context.world.appDriver.waitForAppToSettle();
    final finder = context.world.appDriver.findBy(key.name, FindType.key);
    final Widget widget = finder.evaluate().single.widget;

    await context.world.appDriver.scrollIntoView(finder);
    await context.world.appDriver.waitForAppToSettle();

    final String? text;

    switch (widget.runtimeType) {
      case const (ReactiveTextField):
        text = (widget as ReactiveTextField).state.controller.text;
        break;

      case const (CopyableTextField):
        text = (widget as CopyableTextField).state.controller.text;
        break;

      case const (UserNumCopyable):
        text = (widget as UserNumCopyable).num.toString();
        break;

      default:
        throw ArgumentError('Nothing to copy from ${widget.runtimeType}.');
    }

    context.world.clipboard = ClipboardData(text: text);
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 30),
);

/// Enters the given [text] into the widget with the provided [WidgetKey].
Future<void> _fillField(
  WidgetKey key,
  String text,
  StepContext<FlutterWorld> context,
) async {
  await context.world.appDriver.waitUntil(() async {
    final finder = context.world.appDriver.findByKeySkipOffstage(key.name);

    if (await context.world.appDriver.isPresent(finder)) {
      await context.world.appDriver.waitForAppToSettle();

      await context.world.appDriver.scrollIntoView(finder);
      await context.world.appDriver.waitForAppToSettle();
      await context.world.appDriver
          .tap(finder, timeout: context.configuration.timeout);
      await context.world.appDriver.waitForAppToSettle();

      final finder2 = context.world.appDriver.findByKeySkipOffstage(key.name);
      await context.world.appDriver.scrollIntoView(finder2);
      await context.world.appDriver.enterText(finder2, text);

      await context.world.appDriver.waitForAppToSettle();

      FocusManager.instance.primaryFocus?.unfocus();
      return true;
    }

    return false;
  });
}

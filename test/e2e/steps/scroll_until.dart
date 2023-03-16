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
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';

import '../configuration.dart';
import '../parameters/keys.dart';

/// Scrolls the provided [Scrollable] until the specified [WidgetKey] is present
/// within that list.
///
/// Examples:
/// - Then I scroll `Menu` until `LogoutButton` is present
final StepDefinitionGeneric<FlutterWorld> scrollUntilPresent =
    then2<WidgetKey, WidgetKey, FlutterWorld>(
  RegExp(r'I scroll {key} until {key} is present'),
  (WidgetKey list, WidgetKey key, StepContext<FlutterWorld> context) async {
    await context.world.appDriver.waitForAppToSettle();

    await context.world.appDriver.scrollUntilVisible(
      context.world.appDriver.findByKeySkipOffstage(key.name),
      scrollable: find.descendant(
        of: find.byKey(Key(list.name)),
        matching: find.byWidgetPredicate((widget) {
          // TODO: Find a proper way to differentiate [Scrollable]s from
          //       [TextField]s:
          //       https://github.com/flutter/flutter/issues/76981
          if (widget is Scrollable) {
            return widget.restorationId == null;
          }
          return false;
        }),
      ),
      dy: 100,
    );

    await context.world.appDriver.waitForAppToSettle();
  },
);

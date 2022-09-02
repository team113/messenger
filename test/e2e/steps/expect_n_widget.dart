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
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';

import '../parameters/keys.dart';

/// Checks the required number of widgets.
///
/// Examples:
/// - Then I expect 1 `ChatMessage`
final expectNWidget = then2<int, WidgetKey, FlutterWorld>(
  RegExp(r'I expect {int} {key}'),
  (quantity, key, context) async {
    await context.world.appDriver.waitForAppToSettle();

    final finder = find.byKey(Key(key.name), skipOffstage: false);
    await context.world.appDriver.scrollIntoView(finder.last);
    await context.world.appDriver.waitForAppToSettle();

    final finder2 = find.byKey(Key(key.name), skipOffstage: false);
    context.expectMatch(finder2.evaluate().length, quantity);
  },
);

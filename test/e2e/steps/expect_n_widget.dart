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
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';

import '../parameters/keys.dart';

/// Indicates whether the provided number of specific [Widget]s are visible.
///
/// Examples:
/// - Then I expect to see 1 `ChatMessage`
final StepDefinitionGeneric<FlutterWorld> expectNWidget =
    then2<int, WidgetKey, FlutterWorld>(
  RegExp(r'I expect to see {int} {key}'),
  (int quantity, _, StepContext<FlutterWorld> context) async {
    await context.world.appDriver.waitForAppToSettle();
    final FlutterListView listMessages = find
        .byType(FlutterListView)
        .evaluate()
        .single
        .widget as FlutterListView;
    context.expectMatch(listMessages.delegate.estimatedChildCount, quantity);
  },
);

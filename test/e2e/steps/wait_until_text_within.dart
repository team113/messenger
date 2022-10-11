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

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_gherkin/src/flutter/parameters/existence_parameter.dart';
import 'package:gherkin/gherkin.dart';

import '../parameters/keys.dart';

/// Waits until the provided text is present or absent within widget.
///
/// Examples:
/// - Then I wait until text "Dummy" is absent within the `WidgetKey`
/// - Then I wait until text "Dummy" is present within the `WidgetKey`
final StepDefinitionGeneric untilTextExistsWithin =
    then3<String, Existence, WidgetKey, FlutterWorld>(
  'I wait until text {string} is {existence} within the {key}',
  (text, existence, key, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();
        var finder = context.world.appDriver.findByDescendant(
          context.world.appDriver.findBy(key.name, FindType.key),
          context.world.appDriver.findBy(text, FindType.text),
          firstMatchOnly: true,
        );
        return existence == Existence.absent
            ? context.world.appDriver.isAbsent(finder)
            : context.world.appDriver.isPresent(finder);
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

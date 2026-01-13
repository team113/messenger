// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/log.dart';

import '../configuration.dart';
import '../parameters/keys.dart';

/// Submits the field present at the [WidgetKey] key.
///
/// Examples:
/// - Then I submit `EmailField` field
StepDefinitionGeneric submitField = when1<WidgetKey, FlutterWorld>(
  'I submit {key} field',
  (key, context) async {
    await context.world.appDriver.waitUntil(() async {
      final finder = context.world.appDriver.findByKeySkipOffstage(key.name);

      Log.debug('submitField($key) -> finder is $finder', 'E2E');

      final bool isPresent = await context.world.appDriver.isPresent(finder);

      Log.debug(
        'submitField($key) -> isPresent($isPresent), tryEvaluate(${finder.tryEvaluate()})',
        'E2E',
      );

      if (isPresent && finder.tryEvaluate()) {
        final input = await context.world.appDriver.widget(finder);
        if (input is ReactiveTextField) {
          final ReactiveFieldState state = input.state;
          if (state is TextFieldState) {
            Log.debug(
              'submitField($key) -> input is `ReactiveTextField`, so just do `submit()`',
              'E2E',
            );

            state.submit();

            await context.world.appDriver.waitForAppToSettle();

            return true;
          }
        }
      }

      return false;
    }, timeout: const Duration(seconds: 60));
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 60),
);

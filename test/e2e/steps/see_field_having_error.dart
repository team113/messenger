// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:gherkin/gherkin.dart';

import '../configuration.dart';
import '../parameters/keys.dart';
import '../world/custom_world.dart';

/// Indicates whether a [ReactiveTextField] specified by the key has an error.
///
/// Examples:
/// - Then I see `RecoveryCodeField` having an error
final StepDefinitionGeneric seeFieldHavingAnError =
    then1<WidgetKey, CustomWorld>('I see {key} having an error', (
      name,
      context,
    ) async {
      await _fieldHavingError(name.name, context, hasError: true);
    });

/// Indicates whether a [ReactiveTextField] specified by the key has no error.
///
/// Examples:
/// - Then I see `RecoveryCodeField` having no error
final StepDefinitionGeneric seeFieldHavingNoError =
    then1<WidgetKey, CustomWorld>('I see {key} having no error', (
      name,
      context,
    ) async {
      await _fieldHavingError(name.name, context, hasError: false);
    });

Future<void> _fieldHavingError(
  String key,
  StepContext<CustomWorld> context, {
  bool hasError = true,
}) async {
  await context.world.appDriver.waitUntil(() async {
    final field = context.world.appDriver.findByKeySkipOffstage(key);

    if (await context.world.appDriver.isPresent(field)) {
      final error = context.world.appDriver.findByDescendant(
        field,
        context.world.appDriver.findByKeySkipOffstage('HasError'),
        firstMatchOnly: true,
      );

      switch (hasError) {
        case true:
          return await context.world.appDriver.isPresent(error);

        case false:
          return await context.world.appDriver.isAbsent(error);
      }
    }

    return false;
  }, timeout: const Duration(seconds: 30));
}

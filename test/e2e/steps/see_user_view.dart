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
import '../world/custom_world.dart';

/// Waits until the [UserView] being displayed has the provided title.
///
/// Examples:
/// - Then I see title as "Bob" in user profile
final StepDefinitionGeneric seeTitleInUserView = then1<String, CustomWorld>(
  'I see title as {string} in user profile',
  (String title, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final finder = context.world.appDriver.findByKeySkipOffstage(
        'UserViewTitleKey',
      );

      final String? text = await context.world.appDriver.getText(finder);
      if (text == title) {
        return true;
      }

      return false;
    }, timeout: const Duration(seconds: 30));
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

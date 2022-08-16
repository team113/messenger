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

import 'package:gherkin/gherkin.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Taps provided user in users search result.
///
/// Examples:
/// - Then I tap Bob in search
final StepDefinitionGeneric tapUserInSearch = then1<TestUser, CustomWorld>(
  'I tap {user} in search',
  (user, context) async {
    await context.world.appDriver.waitForAppToSettle();

    String userKey = 'FoundUser_${context.world.sessions[user.name]!.userId}';
    final finder = context.world.appDriver.findByKeySkipOffstage(userKey);

    await context.world.appDriver.scrollIntoView(finder);
    await context.world.appDriver.waitForAppToSettle();
    await context.world.appDriver.tap(
      finder,
      timeout: context.configuration.timeout,
    );
    await context.world.appDriver.waitForAppToSettle();
  },
);

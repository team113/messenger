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

import 'package:gherkin/gherkin.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Taps on a [Chat]-dialog with the provided [User].
///
/// Examples:
/// - When I tap on chat with Bob
final StepDefinitionGeneric iTapChatWith = when1<TestUser, CustomWorld>(
  'I tap on chat with {user}',
  (TestUser user, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final finder = context.world.appDriver
          .findByKeySkipOffstage(
            'Chat_${context.world.sessions[user.name]!.dialog!.val}',
          )
          .last;

      if (await context.world.appDriver.isPresent(finder)) {
        await context.world.appDriver.scrollIntoView(finder);
        await context.world.appDriver.waitForAppToSettle();
        await context.world.appDriver.tap(
          finder,
          timeout: context.configuration.timeout,
        );
        await context.world.appDriver.waitForAppToSettle();
        return true;
      }

      return false;
    });
  },
);

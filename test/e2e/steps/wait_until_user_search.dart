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

import 'package:flutter_gherkin/src/flutter/parameters/existence_parameter.dart';
import 'package:gherkin/gherkin.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Waits until provided user is present or absent in users search result.
///
/// Examples:
/// - Then I wait until Bob is present in search
/// - Then I wait until Bob is absent in search
final StepDefinitionGeneric untilUserInSearch =
    then2<TestUser, Existence, CustomWorld>(
  'I wait until {user} is {existence} in search',
  (user, existence, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        String userKey =
            'FoundUser_${context.world.sessions[user.name]!.userId}';

        return existence == Existence.absent
            ? context.world.appDriver.isAbsent(
                context.world.appDriver.findByKeySkipOffstage(userKey),
              )
            : context.world.appDriver.isPresent(
                context.world.appDriver.findByKeySkipOffstage(userKey),
              );
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

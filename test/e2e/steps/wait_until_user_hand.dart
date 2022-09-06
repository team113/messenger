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
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/service/auth.dart';

import '../parameters/hand_status.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Waits until the authenticated [MyUser]'s hand is lowered or raised in
/// currently active call.
///
/// Examples:
/// - Then I wait until my hand is lowered
/// - Then I wait until my hand is raised
final StepDefinitionGeneric untilMyUserHand = then1<HandStatus, CustomWorld>(
  'I wait until my hand is {hand}',
  (handStatus, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        String userKey = 'Participant_${Get.find<AuthService>().userId!}';
        final finder = context.world.appDriver.findByDescendant(
          context.world.appDriver.findBy(userKey, FindType.key),
          context.world.appDriver.findBy('RaisedHand', FindType.key),
        );

        return handStatus == HandStatus.lower
            ? context.world.appDriver.isAbsent(finder)
            : context.world.appDriver.isPresent(finder);
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

/// Waits until the provided [TestUser]'s hand is lowered or raised in currently
/// active call.
///
/// Examples:
/// - Then I wait until Bob hand is raised
/// - Then I wait until Bob hand is lowered
final StepDefinitionGeneric untilUserHand =
    then2<TestUser, HandStatus, CustomWorld>(
  'I wait until {user} hand is {hand}',
  (user, handStatus, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        String userKey =
            'Participant_${context.world.sessions[user.name]!.userId}';
        final finder = context.world.appDriver.findByDescendant(
          context.world.appDriver.findBy(userKey, FindType.key),
          context.world.appDriver.findBy('RaisedHand', FindType.key),
        );

        return handStatus == HandStatus.lower
            ? context.world.appDriver.isAbsent(finder)
            : context.world.appDriver.isPresent(finder);
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

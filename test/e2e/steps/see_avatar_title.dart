// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Waits until the [Avatar] being displayed has the provided title.
///
/// Examples:
/// - Then I see avatar title as "Deleted Account"
final StepDefinitionGeneric seeAvatarTitle = then1<String, CustomWorld>(
  'I see avatar title as {string}',
  (String title, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final finder = context.world.appDriver.findByKeySkipOffstage(
        'AvatarTitleKey',
      );

      for (int i = 0; i < finder.allCandidates.length; i++) {
        final text = await context.world.appDriver.getText(finder.at(i));

        if (text == title) {
          return true;
        }
      }

      return false;
    }, timeout: const Duration(seconds: 30));
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Waits until the [UserAvatar] being displayed has the provided title.
///
/// Examples:
/// - Then I see user avatar title as "Deleted Account"
final StepDefinitionGeneric seeUserAvatarTitle = then1<String, CustomWorld>(
  'I see user avatar title as {string}',
      (String title, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final userId = router.route.split('/')[2];

      final finder = context.world.appDriver.findByDescendant(
        context.world.appDriver.findBy('UserAvatar_$userId', FindType.key),
        context.world.appDriver.findByKeySkipOffstage('AvatarTitleKey'),
        firstMatchOnly: true,
      );

      final text = await context.world.appDriver.getText(finder);

      if (text == title) {
        return true;
      }

      return false;
    }, timeout: const Duration(seconds: 30));
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

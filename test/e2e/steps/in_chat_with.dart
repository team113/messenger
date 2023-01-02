// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Routes the [router] to the [Chat]-dialog page with the provided [TestUser].
///
/// Examples:
/// - Given I am in chat with Bob
final StepDefinitionGeneric iAmInChatWith = given1<TestUser, CustomWorld>(
  'I am in chat with {user}',
  (TestUser user, context) async {
    router.chat(context.world.sessions[user.name]!.dialog!);

    await context.world.appDriver.waitUntil(
      () async {
        return context.world.appDriver.isPresent(
          context.world.appDriver.findBy('ChatView', FindType.key),
        );
      },
    );
  },
);

/// Routes the [router] to the [Chat]-group page with the provided [ChatName].
///
/// Examples:
/// - Given I am in "Example" chat
final StepDefinitionGeneric iAmInChatNamed = given1<String, CustomWorld>(
  'I am in {string} chat',
  (String chatName, context) async {
    router.chat(context.world.groups[chatName]!);

    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();
        return context.world.appDriver.isPresent(
          context.world.appDriver.findBy('ChatView', FindType.key),
        );
      },
    );
  },
);

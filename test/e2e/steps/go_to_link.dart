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

import 'package:gherkin/gherkin.dart';
import 'package:messenger/routes.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Routes the [RouterState] to the provided [TestUser]'s direct link page.
final StepDefinitionGeneric goToUserLink = then1<TestUser, CustomWorld>(
  "I go to {user}'s direct link",
  (TestUser user, context) async {
    router.link(context.world.sessions[user.name]!.first.slug!);
    await context.world.appDriver.waitForAppToSettle();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 1),
);

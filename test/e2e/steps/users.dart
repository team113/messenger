// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Creates a new [MyUser] and signs him in.
///
/// Examples:
/// - Given I am Alice
final StepDefinitionGeneric iAm = given1<TestUser, CustomWorld>(
  'I am {user}',
  (TestUser user, context) async {
    var password = UserPassword('123');

    final CustomUser me = await createUser(
      user: user,
      world: context.world,
      password: password,
    );
    context.world.me = me.userId;

    await Get.find<AuthService>().signIn(
      password,
      num: context.world.sessions[user.name]?.userNum,
      unsafe: true,
      force: true,
    );

    router.home();

    // Ensure business logic is initialized.
    await context.world.appDriver.waitUntil(() async {
      return Get.isRegistered<ChatService>() &&
          Get.isRegistered<MyUserService>();
    });
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Signs in as the provided [TestUser] created earlier in the [iAm] step.
///
/// Examples:
/// - `I sign in as Alice`
final StepDefinitionGeneric signInAs = then1<TestUser, CustomWorld>(
  'I sign in as {user}',
  (TestUser user, context) async {
    try {
      await Get.find<AuthService>()
          .signInWith(await context.world.sessions[user.name]!.credentials);
    } catch (_) {
      var password = UserPassword('123');

      await Get.find<AuthService>().signIn(
        password,
        num: context.world.sessions[user.name]!.userNum,
        unsafe: true,
        force: true,
      );
    }

    router.home();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Logouts the currently authenticated [MyUser].
///
/// Examples:
/// - `I logout`
final StepDefinitionGeneric logout = then<CustomWorld>(
  'I logout',
  (context) async {
    final CustomUser me = context.world.sessions.values
        .firstWhere((e) => e.userId == context.world.me);
    router.go(await Get.find<AuthService>().logout());
    me.credentials = null;
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates a new [User] identified by the provided name.
///
/// Examples:
/// - `Given user Bob`
final StepDefinitionGeneric user = given1<TestUser, CustomWorld>(
  'user {user}',
  (TestUser name, context) => createUser(user: name, world: context.world),
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates two new [User]s identified by the provided names.
///
/// Examples:
/// - `Given users Bob and Charlie`
final twoUsers = given2<TestUser, TestUser, CustomWorld>(
  'users {user} and {user}',
  (TestUser user1, TestUser user2, context) async {
    await createUser(user: user1, world: context.world);
    await createUser(user: user2, world: context.world);
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates the provided count of new [User]s with the provided name.
///
/// Examples:
/// - `Given 10 users Bob`
/// - `Given 20 users Charlie`
final countUsers = given2<int, TestUser, CustomWorld>(
  '{int} users {user}',
  (int count, TestUser user, context) async {
    for (int i = 0; i < count; i++) {
      await createUser(user: user, world: context.world);
    }
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

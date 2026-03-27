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

import 'dart:math';

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/api/backend/extension/credentials.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Creates a new [MyUser] and signs him in.
///
/// Examples:
/// - Given I am Alice
final StepDefinitionGeneric iAm = given1<TestUser, CustomWorld>(
  'I am {user}\$',
  (TestUser user, context) async {
    var password = UserPassword('123');

    final CustomUser me = await createUser(
      user: user,
      world: context.world,
      password: password,
    );
    context.world.me = me.userId;

    final AuthService authService = Get.find<AuthService>();
    await authService.signInWith(await me.credentials);
    me.credentials = authService.credentials.value;

    router.home();

    // Ensure business logic is initialized.
    await context.world.appDriver.waitUntil(() async {
      return Get.isRegistered<ChatService>() &&
          Get.isRegistered<MyUserService>();
    }, timeout: const Duration(seconds: 30));
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 30),
);

/// Signs in as the provided [TestUser] created earlier in the [iAm] step.
///
/// Examples:
/// - `I sign in as Alice`
final StepDefinitionGeneric signInAs = then1<TestUser, CustomWorld>(
  'I sign in as {user}\$',
  (TestUser user, context) async {
    try {
      await Get.find<AuthService>().signInWith(
        await context.world.sessions[user.name]!.credentials,
      );
    } catch (_) {
      await Get.find<AuthService>().signIn(
        password: UserPassword('123'),
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
  'I logout\$',
  (context) async {
    final CustomUser me = context.world.sessions.values
        .firstWhere((e) => e.userId == context.world.me)
        .first;
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
  r'user {user}$',
  (TestUser name, context) => createUser(user: name, world: context.world),
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates a new [User] identified by the provided name and password.
///
/// Examples:
/// - `Given user Bob with their password set`
final StepDefinitionGeneric userWithPassword = given1<TestUser, CustomWorld>(
  'user {user} with their password set',
  (TestUser name, context) => createUser(
    user: name,
    password: UserPassword('123'),
    world: context.world,
  ),
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates two new [User]s identified by the provided names.
///
/// Examples:
/// - `Given users Bob and Charlie`
final twoUsers = given2<TestUser, TestUser, CustomWorld>(
  'users {user} and {user}\$',
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
  '{int} users {user}\$',
  (int count, TestUser user, context) async {
    for (int i = 0; i < count; i++) {
      await createUser(user: user, world: context.world);
    }
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Simulates a [TestUser] deleting their account.
///
/// Examples:
/// - `Bob deletes their account`
final StepDefinitionGeneric deleteUser = then1<TestUser, CustomWorld>(
  '{user} deletes their account',
  (TestUser testUser, context) async {
    final GraphQlProvider provider = GraphQlProvider();
    final CustomUser user = context.world.sessions[testUser.name]!.first;
    final Credentials credentials = await user.credentials;
    provider.token = credentials.access.secret;

    await provider.deleteMyUser();

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Signs in as the provided [TestUser] to create additional [Session] for them.
///
/// Examples:
/// - `Alice has another active session`
final StepDefinitionGeneric hasSession = then1<TestUser, CustomWorld>(
  '{user} has another active session\$',
  (TestUser testUser, context) async {
    final GraphQlProvider provider = GraphQlProvider()
      ..client.withWebSocket = false;

    final CustomUser user = context.world.sessions[testUser.name]!.first;

    final result = await provider.signIn(
      identifier: MyUserIdentifier(num: user.userNum),
      credentials: MyUserCredentials(password: user.password),
    );

    final CustomUser newUser = CustomUser(result.toModel(), result.user.num);
    context.world.sessions[testUser.name]?.add(newUser);

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Signs out as the provided [TestUser] from any additional [Session] for them.
///
/// Examples:
/// - `Alice signs out of another active sessions`
final StepDefinitionGeneric signsOutSession = then1<TestUser, CustomWorld>(
  '{user} signs out of another active sessions\$',
  (TestUser testUser, context) async {
    final GraphQlProvider provider = GraphQlProvider()
      ..client.withWebSocket = false;

    final sessions = context.world.sessions[testUser.name] ?? [];

    for (var e in sessions.skip(1)) {
      await provider.deleteSession(token: e.token);
    }

    sessions.removeRange(min(sessions.length, 0), sessions.length);

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

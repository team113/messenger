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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Creates a dialog by the provided [TestUser] with the provided [TestUser].
///
/// Examples:
/// - Given Bob has dialog with me
/// - Given Bob has dialog with Charlie
final StepDefinitionGeneric hasDialog = given2<TestUser, TestUser, CustomWorld>(
  '{user} has dialog with {user}',
  (TestUser user, TestUser withUser, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.token;

    ChatMixin dialog = await provider
        .createDialogChat(context.world.sessions[withUser.name]!.userId);

    context.world.sessions[user.name]!.dialogs[withUser] = dialog.id;
    context.world.sessions[withUser.name]!.dialogs[user] = dialog.id;
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates a group by the provided [TestUser] with provided name and the
/// provided [TestUser].
///
/// Examples:
/// - Given Bob has "Name" group with me
/// - Given Bob has "Name" group with Charlie
final StepDefinitionGeneric hasGroupNamed =
    given3<TestUser, String, TestUser, CustomWorld>(
  '{user} has {string} group with {user}',
  (TestUser user, String name, TestUser withUser, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.token;

    ChatMixin group = await provider.createGroupChat(
      [context.world.sessions[withUser.name]!.userId],
      name: ChatName(name),
    );

    context.world.groups[name] = group.id;
    context.world.sessions[user.name]!.groups[name] = group.id;
    context.world.sessions[withUser.name]!.groups[name] = group.id;
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates a [Chat]-group with the provided [User] and the authenticated
/// [MyUser].
///
/// Examples:
/// - Given I have "Name" group with Bob.
final StepDefinitionGeneric haveGroupNamed =
    given2<String, TestUser, CustomWorld>(
  'I have {string} group with {user}',
  (String name, TestUser user, context) async {
    final AuthService authService = Get.find();
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.token;

    var chat = await provider.createGroupChat(
      [authService.credentials.value!.userId],
      name: ChatName(name),
    );

    context.world.groups[name] = chat.id;
    context.world.me!.groups[name] = chat.id;
    context.world.sessions[user.name]!.groups[name] = chat.id;
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

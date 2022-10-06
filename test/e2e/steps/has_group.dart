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
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Creates a [Chat]-group of the provided [User] with the authenticated
/// [MyUser] with specified chat name.
///
/// Examples:
/// - Given I am in group "Chat name" with Bob.
final StepDefinitionGeneric hasGroupChatWithMe =
    given2<String, TestUser, CustomWorld>(
  'I am in group {string} with {user}',
  (String chatName, TestUser user, context) async {
    final AuthService authService = Get.find();
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.session.token;
    var chat = await provider.createGroupChat(
      [authService.credentials.value!.userId],
      name: ChatName(chatName),
    );
    context.world.groups[chatName] = chat.id;
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates a [Chat]-group of the provided [User] with the authenticated
/// [MyUser] with specified chat name.
///
/// Examples:
/// - Given I am in group "Chat name" with Bob.
final StepDefinitionGeneric inGroupWithUser = given1<TestUser, CustomWorld>(
  'I am in group with {user}',
  (TestUser user, context) async {
    final AuthService authService = Get.find();
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.session.token;
    await provider.createGroupChat(
      [authService.credentials.value!.userId],
    );
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

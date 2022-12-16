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
import 'package:messenger/api/backend/schema.dart' show ChatContactRecord;
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Creates a [ChatContact] with the provided [User] in the address book of the
/// authenticated [MyUser].
///
/// Examples:
/// - Given contact Bob
final StepDefinitionGeneric contact = given1<TestUser, CustomWorld>(
  'contact {user}',
  (TestUser user, context) async {
    final AuthService authService = Get.find();
    final provider = GraphQlProvider();
    provider.token = authService.credentials.value!.session.token;

    final contact = await provider.createChatContact(
      name: UserName(user.name),
      records: [
        ChatContactRecord(userId: context.world.sessions[user.name]!.userId)
      ],
    );

    context.world.contacts[user.name] = contact.events
        .firstWhere((e) => e.$$typename == 'EventChatContactCreated')
        .contactId;

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates two [ChatContact]s of the provided [User]s.
///
/// Examples:
/// - Given contacts Bob and Charlie
final twoContacts = given2<TestUser, TestUser, CustomWorld>(
  'contacts {user} and {user}',
  (TestUser user1, TestUser user2, context) async {
    final AuthService authService = Get.find();
    final provider = GraphQlProvider();
    provider.token = authService.credentials.value!.session.token;

    final contact1 = await provider.createChatContact(
      name: UserName(user1.name),
      records: [
        ChatContactRecord(userId: context.world.sessions[user1.name]!.userId)
      ],
    );

    context.world.contacts[user1.name] = contact1.events
        .firstWhere((e) => e.$$typename == 'EventChatContactCreated')
        .contactId;

    final contact2 = await provider.createChatContact(
      name: UserName(user2.name),
      records: [
        ChatContactRecord(userId: context.world.sessions[user2.name]!.userId)
      ],
    );

    context.world.contacts[user2.name] = contact2.events
        .firstWhere((e) => e.$$typename == 'EventChatContactCreated')
        .contactId;

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

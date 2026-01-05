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

import 'package:gherkin/gherkin.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Adds the specified amount of [ChatContact]s for the provided [TestUser].
///
/// Examples:
/// - Given Alice has 5 contacts.
final StepDefinitionGeneric hasContacts = given2<TestUser, int, CustomWorld>(
  '{user} has {int} contacts',
  (TestUser user, int count, context) async {
    final GraphQlProvider provider = GraphQlProvider()
      ..client.withWebSocket = false
      ..token = context.world.sessions[user.name]?.token;

    List<Future> futures = [];

    for (int i = 0; i < count; i++) {
      futures.add(
        provider.createChatContact(
          name: UserName(i.toString().padLeft(2, '0')),
        ),
      );
    }

    await Future.wait(futures);

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Adds the specified amount of favorite [ChatContact]s for the provided
/// [TestUser].
///
/// Examples:
/// - Given Alice has 5 favorite contacts.
final StepDefinitionGeneric
hasFavoriteContacts = given2<TestUser, int, CustomWorld>(
  '{user} has {int} favorite contacts',
  (TestUser user, int count, context) async {
    final GraphQlProvider provider = GraphQlProvider()
      ..client.withWebSocket = false
      ..token = context.world.sessions[user.name]?.token;

    List<Future> futures = [];

    for (int i = 0; i < count; i++) {
      Future future = Future(() async {
        final ChatContactEventsVersionedMixin result = await provider
            .createChatContact(name: UserName(i.toString().padLeft(2, '0')));
        final ChatContactId contactId =
            (result.events.first
                    as ChatContactEventsVersionedMixin$Events$EventChatContactCreated)
                .contactId;

        provider.favoriteChatContact(
          contactId,
          ChatContactFavoritePosition((i + 1).toDouble()),
        );
      });

      futures.add(future);
    }

    await Future.wait(futures);

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

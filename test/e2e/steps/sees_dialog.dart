// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:collection/collection.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/api/backend/schema.dart' show ChatKind;
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Ensures that the provided [User] has a dialog with the authenticated
/// [MyUser] in their recent [Chat]s.
///
/// Examples:
/// - Then Bob sees dialog with me in recent chats.
final StepDefinitionGeneric seesDialogWithMe = then1<TestUser, CustomWorld>(
  '{user} sees dialog with me in recent chats',
  (TestUser user, context) async {
    final provider = GraphQlProvider();

    try {
      await context.world.appDriver.waitUntil(() async {
        provider.token = context.world.sessions[user.name]?.session.token;
        final dialog = (await provider.recentChats(first: 120))
            .recentChats
            .nodes
            .firstWhereOrNull((e) =>
                e.kind == ChatKind.dialog &&
                e.members.nodes.any((m) => m.user.id == context.world.me));
        return dialog != null;
      });
    } finally {
      provider.disconnect();
    }
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Ensures that the provided [User] has no dialog with the authenticated
/// [MyUser] in their recent [Chat]s.
///
/// Examples:
/// - Then Bob sees no dialog with me in recent chats.
final StepDefinitionGeneric seesNoDialogWithMe = then1<TestUser, CustomWorld>(
  '{user} sees no dialog with me in recent chats',
  (TestUser user, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.session.token;
    final dialog = (await provider.recentChats(first: 120))
        .recentChats
        .nodes
        .firstWhereOrNull((e) =>
            e.kind == ChatKind.dialog &&
            e.members.nodes.any((m) => m.user.id == context.world.me));
    provider.disconnect();
    assert(dialog == null, true);
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

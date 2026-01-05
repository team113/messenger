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
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Removes the specified [TestUser] from the provided [Chat]-group on other
/// user's behalf.
///
/// Examples:
/// - And Bob removes Alice from "Alice and Bob" group
final StepDefinitionGeneric
removeGroupMember = then3<TestUser, TestUser, String, CustomWorld>(
  RegExp(r'{user} removes {user} from {string} group'),
  (TestUser user, TestUser member, String groupName, context) async {
    final CustomUser? kicker = context.world.sessions[user.name]?.firstOrNull;
    final CustomUser? kicked = context.world.sessions[member.name]?.firstOrNull;
    final ChatId? groupId = context.world.groups[groupName];

    if (kicker == null) {
      throw ArgumentError(
        '`${user.name}` is not found in `CustomWorld.sessions`.',
      );
    } else if (kicked == null) {
      throw ArgumentError(
        '`${member.name}` is not found in `CustomWorld.sessions`.',
      );
    } else if (groupId == null) {
      throw ArgumentError('`$groupName` is not found in `CustomWorld.groups`.');
    }

    final GraphQlProvider provider = GraphQlProvider()
      ..client.withWebSocket = false
      ..token = kicker.token;

    await provider.removeChatMember(groupId, kicked.userId);

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

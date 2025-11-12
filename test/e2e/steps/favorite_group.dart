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
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Favorites group with the provided name by the provided [TestUser].
///
/// Examples:
/// - When Alice favorites "Name" group
final StepDefinitionGeneric favoriteGroup =
    when2<TestUser, String, CustomWorld>(
      RegExp(r'{user} favorites {string} group$'),
      (TestUser user, String name, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false;

        final CustomUser customUser = context.world.sessions[user.name]!.first;
        provider.token = (await customUser.credentials).access.secret;

        // TODO: Should use `searchChats` query or something, when backend
        //       introduces such a query.
        final Chat chat = (await provider.recentChats(first: 10))
            .recentChats
            .edges
            .map((e) => e.node.toModel())
            .firstWhere((e) => e.name?.val == name);

        await provider.favoriteChat(
          chat.id,
          ChatFavoritePosition(
            DateTime.now().millisecondsSinceEpoch.toDouble(),
          ),
        );

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

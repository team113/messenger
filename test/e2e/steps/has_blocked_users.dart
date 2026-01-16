// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Blocks the provided count of [User]s.
///
/// Examples:
/// - When Alice has 30 blocked users
final StepDefinitionGeneric blockedCountUsers =
    when2<TestUser, int, CustomWorld>(
      '{user} has {int} blocked users',
      (user, count, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        try {
          for (int i = 0; i < count; i++) {
            final CustomUser user = await createUser();
            await provider.blockUser(user.userId, null);

            // Reduce possible request spam.
            await Future.delayed(Duration(milliseconds: 250));
          }
        } finally {
          provider.disconnect();
        }
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = Duration(minutes: 5),
    );

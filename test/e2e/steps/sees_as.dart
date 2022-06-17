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

import 'package:gherkin/gherkin.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/api/backend/extension/user.dart';

import '../parameters/online_status.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Indicates whether the provided [TestUser] sees other [TestUser] as the
/// specified [OnlineStatus] or not.
final StepDefinitionGeneric seesAs =
    then3<TestUser, TestUser, OnlineStatus, CustomWorld>(
  '{user} sees {user} as {status}',
  (TestUser user1, TestUser user2, OnlineStatus status, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user1.name]?.session.token;

    await context.world.appDriver.waitUntil(() async {
      var response =
          await provider.getUser(context.world.sessions[user2.name]!.userId);
      var user = response.user?.toModel();

      return (status == OnlineStatus.online && user?.online == true) ||
          (status == OnlineStatus.offline && user?.online == false);
    }, pollInterval: const Duration(seconds: 1));

    provider.disconnect();
  },
);

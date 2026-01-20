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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/util/log.dart';

import '../parameters/blocked_status.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Indicates whether the [TestUser] is blocked or unblocked for the current
/// [MyUser].
///
/// Examples:
/// - Then Bob is indeed blocked
/// - Then Bob is indeed unblocked
final StepDefinitionGeneric
userIsBlocked = then2<TestUser, BlockedStatus, CustomWorld>(
  '{user} is indeed {blocked}',
  (user, blocked, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false;

        final AuthService authService = Get.find();
        provider.token = authService.credentials.value!.access.secret;

        Log.debug(
          'userIsBlocked -> await getUser(${context.world.sessions[user.name]?.userId})...',
          'E2E',
        );

        final mixin = await provider.getUser(
          context.world.sessions[user.name]!.userId,
        );

        Log.debug(
          'userIsBlocked -> await getUser(${context.world.sessions[user.name]?.userId})... done -> $mixin',
          'E2E',
        );

        final bool isBlocked = mixin?.isBlocked.record != null;

        Log.debug('userIsBlocked -> `isBlocked` is $isBlocked', 'E2E');

        provider.disconnect();

        return switch (blocked) {
          BlockedStatus.blocked => isBlocked,
          BlockedStatus.unblocked => !isBlocked,
        };
      },
      timeout: const Duration(seconds: 30),
      pollInterval: const Duration(seconds: 4),
    );
  },
);

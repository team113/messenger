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

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/service/auth.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Indicates whether the provided [TestUser] in in the accounts list.
///
/// Examples:
/// - Then I see Alice account in accounts list
final StepDefinitionGeneric seeAccountInAccounts = then1<TestUser, CustomWorld>(
  'I see {user} account in accounts list',
  (name, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle(timeout: 1.seconds);

      final authService = Get.find<AuthService>();
      final account = authService.profiles.firstWhereOrNull(
        (e) => e.name?.val == name.name,
      );
      return context.world.appDriver.isPresent(
        context.world.appDriver.findBy('Account_${account?.id}', FindType.key),
      );
    }, timeout: const Duration(seconds: 30));
  },
);

/// Taps on the provided [TestUser] in in the accounts list.
///
/// Examples:
/// - Then I tap on Alice account in accounts list
final StepDefinitionGeneric tapAccountInAccounts = then1<TestUser, CustomWorld>(
  'I tap on {user} account in accounts list',
  (name, context) async {
    await context.world.appDriver.waitForAppToSettle(timeout: 1.seconds);

    final authService = Get.find<AuthService>();
    final account = authService.profiles.firstWhereOrNull(
      (e) => e.name?.val == name.name,
    );
    await context.world.appDriver.tap(
      context.world.appDriver.findBy('Account_${account?.id}', FindType.key),
    );
  },
);

/// Taps on remove button of the provided [TestUser] in in the accounts list.
///
/// Examples:
/// - Then I remove Alice account from accounts list
final StepDefinitionGeneric removeAccountInAccounts =
    then1<TestUser, CustomWorld>('I remove {user} account from accounts list', (
      name,
      context,
    ) async {
      await context.world.appDriver.waitForAppToSettle(timeout: 1.seconds);

      final authService = Get.find<AuthService>();
      final account = authService.profiles.firstWhereOrNull(
        (e) => e.name?.val == name.name,
      );
      await context.world.appDriver.tap(
        context.world.appDriver.findByDescendant(
          context.world.appDriver.findBy(
            'Account_${account?.id}',
            FindType.key,
          ),
          context.world.appDriver.findBy('RemoveAccount', FindType.key),
        ),
      );
    });

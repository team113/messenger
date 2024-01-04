// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Sets the [UserLogin] of the provided [TestUser] to the uniquely generated
/// one.
///
/// Examples:
/// - And Alice has her login set up
final StepDefinitionGeneric setLogin = then1<TestUser, CustomWorld>(
  RegExp(r'{user} has (?:his|her) login set up'),
  (TestUser user, context) async {
    final CustomUser? customUser = context.world.sessions[user.name];

    if (customUser == null) {
      throw ArgumentError(
        '`${user.name}` is not found in `CustomWorld.sessions`.',
      );
    }

    await _setLoginTo(customUser);
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Sets the [UserLogin] of [CustomWorld.me] to the uniquely generated one.
///
/// Examples:
/// - And I have my login set up
final StepDefinitionGeneric setMyLogin = then<CustomWorld>(
  'I have my login set up',
  (context) async {
    final CustomUser? me = context.world.sessions.values
        .where((user) => user.userId == context.world.me)
        .firstOrNull;

    if (me == null) {
      throw ArgumentError('`MyUser` is not found in `CustomWorld.sessions`.');
    }

    await _setLoginTo(me);
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Generates and sets an [UserLogin] of the provided [TestUser].
Future<void> _setLoginTo(CustomUser user) async {
  final provider = GraphQlProvider();

  provider.token = user.token;

  final String newLogin = 'lgn_${user.userNum.val}';
  await provider.updateUserLogin(UserLogin(newLogin));

  provider.disconnect();
}

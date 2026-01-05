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
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/credentials.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Sets the specified [TestCredential] of the provided [TestUser] to the
/// uniquely generated one.
///
/// Examples:
/// - And Alice has her login set up
/// - And Bob has his direct link set up
final StepDefinitionGeneric setCredential =
    then2<TestUser, TestCredential, CustomWorld>(
      RegExp(r'{user} has (?:his|her) {credential} set up'),
      (TestUser user, TestCredential credential, context) async {
        final CustomUser? customUser =
            context.world.sessions[user.name]?.firstOrNull;

        if (customUser == null) {
          throw ArgumentError(
            '`${user.name}` is not found in `CustomWorld.sessions`.',
          );
        }

        await _setCredentialTo(customUser, credential);
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Sets the specified [TestCredential] of [CustomWorld.me] to the uniquely
/// generated one.
///
/// Examples:
/// - And I have my login set up
/// - And I have my direct link set up
final StepDefinitionGeneric setMyCredential =
    then1<TestCredential, CustomWorld>(
      'I have my {credential} set up',
      (TestCredential credential, context) async {
        final CustomUser? me = context.world.sessions.values
            .where((user) => user.userId == context.world.me)
            .firstOrNull
            ?.firstOrNull;

        if (me == null) {
          throw ArgumentError(
            '`MyUser` is not found in `CustomWorld.sessions`.',
          );
        }

        await _setCredentialTo(me, credential);
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Generates and sets the specified [TestCredential] of the provided
/// [TestUser].
Future<void> _setCredentialTo(
  CustomUser user,
  TestCredential credential,
) async {
  final GraphQlProvider provider = GraphQlProvider()
    ..client.withWebSocket = false
    ..token = user.token;

  switch (credential) {
    case TestCredential.login:
      final String newLogin = 'lgn_${user.userNum.val}';
      await provider.updateUserLogin(UserLogin(newLogin));
      break;

    case TestCredential.directLink:
      user.slug ??= ChatDirectLinkSlug.generate();
      await provider.createUserDirectLink(user.slug!);
      break;

    case TestCredential.num:
      throw ArgumentError('`UserNum` cannot be set up.');
  }

  provider.disconnect();
}

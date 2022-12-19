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

import '../parameters/hand_status.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Raises or lowers hand by the provided [TestUser] in active call.
///
/// Examples:
/// - When Bob raises hand
/// - When Bob lowers hand
final StepDefinitionGeneric raiseHand =
    when2<TestUser, HandStatus, CustomWorld>(
  '{user} {hand} hand',
  (user, handStatus, context) async {
    CustomUser customUser = context.world.sessions[user.name]!;
    final provider = GraphQlProvider();
    provider.token = customUser.session.token;

    await provider.toggleChatCallHand(
      customUser.call!.chatId.value,
      handStatus == HandStatus.raise,
    );

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

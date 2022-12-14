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
import 'package:messenger/api/backend/schema.dart'
    show PostChatMessageErrorCode;
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Sends a message from the specified [User] to the authenticated [MyUser] in
/// their [Chat]-dialog with the provided text.
///
/// Examples:
/// - Bob sends "Hello, Alice!" message to me
/// - Charlie sends "dummy msg" message to me
final StepDefinitionGeneric sendsMessageToMe =
    and2<TestUser, String, CustomWorld>(
  '{user} sends {string} message to me',
  (TestUser user, String msg, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.session.token;
    await provider.postChatMessage(
      context.world.sessions[user.name]!.dialog!,
      text: ChatMessageText(msg),
    );
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Sends a message from the specified [User] to the authenticated [MyUser] in
/// their [Chat]-dialog and asserts that catched exception is `blacklisted`.
///
/// Examples:
/// - Bob sends message to me and receives blacklist exception
/// - Charlie sends message to me and receives blacklist exception
final StepDefinitionGeneric sendsMessageWithException =
    and1<TestUser, CustomWorld>(
  '{user} sends message to me and receives blacklist exception',
  (TestUser user, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.session.token;
    Object? exception;

    try {
      await provider.postChatMessage(
        context.world.sessions[user.name]!.dialog!,
        text: const ChatMessageText('111'),
      );
    } catch (e) {
      exception = e;
    }

    assert(
      exception is PostChatMessageException &&
          exception.code == PostChatMessageErrorCode.blacklisted,
    );

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

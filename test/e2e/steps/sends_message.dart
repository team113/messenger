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
import 'package:messenger/api/backend/schema.dart'
    show PostChatMessageErrorCode;
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/exception.dart';
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
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        await provider.postChatMessage(
          context.world.sessions[user.name]!.dialog!,
          text: ChatMessageText(msg),
        );

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Sends a text message from the specified [User] to the [Chat]-group with the
/// provided name.
///
/// Examples:
/// - Bob sends "Hello, Alice!" message to "Name" group
/// - Charlie sends "dummy msg" message to "Name" group
final StepDefinitionGeneric sendsMessageToGroup =
    and3<TestUser, String, String, CustomWorld>(
      '{user} sends {string} message to {string} group',
      (TestUser user, String msg, String group, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        await provider.postChatMessage(
          context.world.groups[group]!,
          text: ChatMessageText(msg),
        );

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Sends a message from the specified [User] to the authenticated [MyUser] in
/// their [Chat]-dialog ensuring the thrown exception is of the provided kind.
///
/// Examples:
/// - Bob sends message to me and receives blocked exception
/// - Charlie sends message to me and receives no exception
final StepDefinitionGeneric sendsMessageWithException =
    and2<TestUser, ExceptionType, CustomWorld>(
      '{user} sends message to me and receives {exception} exception',
      (TestUser user, ExceptionType type, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        Object? exception;

        try {
          await provider.postChatMessage(
            context.world.sessions[user.name]!.dialog!,
            text: const ChatMessageText('111'),
          );
        } catch (e) {
          exception = e;
        }

        switch (type) {
          case ExceptionType.blocked:
            assert(
              exception is PostChatMessageException &&
                  exception.code == PostChatMessageErrorCode.blocked,
            );
            break;

          case ExceptionType.no:
            assert(exception == null);
            break;
        }

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Sends the provided count of messages from the specified [TestUser] to the
/// [Chat]-group with the provided name.
///
/// Examples:
/// - Given Alice sends 100 messages to "Name" group
final StepDefinitionGeneric sendsCountMessages =
    given3<TestUser, int, String, CustomWorld>(
      '{user} sends {int} messages to {string} group',
      (TestUser user, int count, String name, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        final ChatId chatId = context.world.groups[name]!;
        for (var i = 0; i < count; ++i) {
          await provider.postChatMessage(chatId, text: ChatMessageText('$i'));
        }

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

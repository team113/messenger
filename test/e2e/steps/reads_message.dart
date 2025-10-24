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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Reads the current [Chat] until the specified message for the provided
/// [User].
///
/// Examples:
/// - Bob reads "Hello, Alice!" message
/// - Charlie reads "dummy msg" message
final StepDefinitionGeneric readsMessage = then2<TestUser, String, CustomWorld>(
  '{user} reads {string} message',
  (TestUser user, String msg, context) async {
    final GraphQlProvider provider = GraphQlProvider()
      ..client.withWebSocket = false
      ..token = context.world.sessions[user.name]?.token;

    final RxChat? chat =
        Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
    final ChatMessage message = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .firstWhere((e) => e.text?.val == msg);

    await provider.readChat(chat.id, message.id);

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Reads all messages by the provided [TestUser] in the [Chat]-group with the
/// provided name.
///
/// Examples:
/// - When Alice reads all messages in "Name" group.
final StepDefinitionGeneric readsAllMessages =
    when2<TestUser, String, CustomWorld>(
      '{user} reads all messages in {string} group',
      (TestUser user, String name, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        final ChatId chatId = context.world.groups[name]!;
        final ChatItemId lastItemId = (await provider.getChat(
          chatId,
        )).chat!.lastItem!.toDto().value.id;

        await provider.readChat(chatId, lastItemId);

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

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
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/store/model/chat_item.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Replies a message with the provided text by the specified [TestUser] in the
/// [Group] with the provided name.
///
/// Examples:
/// - When Alice replies to "dummy msg" message with "reply" text in "Name"
///   group.
final StepDefinitionGeneric repliesToMessage =
    when4<TestUser, String, String, String, CustomWorld>(
      '{user} replies to {string} message with {string} text in {string} group',
      (TestUser user, String text, String reply, String name, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        final ChatId chatId = context.world.groups[name]!;

        // TODO: Should use `searchItems` query or something, when backend
        //       introduces such a query.
        final DtoChatMessage message =
            (await provider.chatItems(chatId, first: 120)).chat!.items.edges
                .map((e) => e.toDto())
                .whereType<DtoChatMessage>()
                .firstWhere((e) => (e.value as ChatMessage).text?.val == text);

        await provider.postChatMessage(
          chatId,
          text: ChatMessageText(reply),
          repliesTo: [message.value.id],
        );

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

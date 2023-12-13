// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Replies first message by the provided [TestUser] in the [Group] with the
/// provided name.
///
/// Examples:
/// - When Alice replies first message in "Name" group.
final StepDefinitionGeneric repliesFirstMessage =
    when2<TestUser, String, CustomWorld>(
  '{user} replies first message in {string} group',
  (TestUser user, String name, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.token;

    final ChatId chatId = context.world.groups[name]!;
    final ChatMessageMixin firstMessage =
        (await provider.chatItems(chatId, last: 3)).chat!.items.edges.first.node
            as ChatMessageMixin;

    await provider.postChatMessage(
      chatId,
      text: const ChatMessageText('reply'),
      repliesTo: [firstMessage.id],
    );

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

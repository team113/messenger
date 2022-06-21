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

import 'package:collection/collection.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Forward a specified message from the specified [User] with specified comment
/// to the authenticated [MyUser] in their [Chat]-dialog with the provided text.
///
/// Examples:
/// - Bob forward "Hello, Alice!" message with comment "Comment" to same chat
/// - Charlie forward "Hello, Bob!" message with comment "Comment" to same chat
final StepDefinitionGeneric sendsForwardMessageToMe =
    and3<TestUser, String, String, CustomWorld>(
  '{user} forward {string} message with comment {string} to same chat',
  (TestUser user, String msg, String comment, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.session.token;

    ChatItemId? messageId;

    ChatHiveProvider chatHive = context.world.authorizedUserChatHive!;

    HiveChat? chat = chatHive.chats.firstWhereOrNull((e) =>
        e.value.getTitle(e.value.members.take(3).map((e) => e.user),
            context.world.sessions[context.world.authorizedUserName]?.userId) ==
        user.name);
    if (chat != null) {
      ChatItemHiveProvider chatItemHiveProvider =
          ChatItemHiveProvider(chat.value.id);
      await chatItemHiveProvider.init(
          userId:
              context.world.sessions[context.world.authorizedUserName]?.userId);
      messageId ??= chatItemHiveProvider.messages
          .firstWhereOrNull((e) =>
              e.value is ChatMessage &&
              (e.value as ChatMessage).text?.val == msg)
          ?.value
          .id;
      messageId ??= chatItemHiveProvider.messages
          .firstWhereOrNull((e) =>
              e.value is ChatForward &&
              (e.value as ChatForward).item is ChatMessage &&
              ((e.value as ChatForward).item as ChatMessage).text?.val == msg)
          ?.value
          .id;

      if (messageId != null) {
        await provider.forwardChatItems(
          chat.value.id,
          chat.value.id,
          [ChatItemQuoteInput(id: messageId, withText: true, attachments: [])],
          text: ChatMessageText(comment),
        );
      }
    }

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

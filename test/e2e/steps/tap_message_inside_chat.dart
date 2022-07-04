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

import 'package:flutter/material.dart';
import 'package:gherkin/gherkin.dart';
import 'package:collection/collection.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Tap message inside specified chat.
///
/// Examples:
/// - I tap "Hello, Alice!" message inside "Bob" chat
/// - I tap "Hello, Alice!" message inside "Charlie" chat
final StepDefinitionGeneric tapMessageInsideChat =
    and2<String, String, CustomWorld>(
  'I tap {string} message inside {string} chat',
  (String msg, String chatName, context) async {
    await context.world.appDriver.waitForAppToSettle();

    ChatHiveProvider chatHive = context.world.authorizedUserChatHive!;
    ChatItemId? messageId;

    for (var chat in chatHive.chats) {
      var name = chat.value.getTitle(
          chat.value.members.take(3).map((e) => e.user),
          context.world.sessions[context.world.authorizedUserName]?.userId);
      if (name == chatName) {
        ChatItemHiveProvider chatItemHiveProvider =
            ChatItemHiveProvider(chat.value.id);
        await chatItemHiveProvider.init(
            userId: context
                .world.sessions[context.world.authorizedUserName]?.userId);
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
          await context.world.appDriver.nativeDriver.tap(context.world.appDriver
              .findByKeySkipOffstage(Key('Message_$messageId')));
          await context.world.appDriver.waitForAppToSettle();
          break;
        }
      }
    }

    await context.world.appDriver.waitForAppToSettle();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

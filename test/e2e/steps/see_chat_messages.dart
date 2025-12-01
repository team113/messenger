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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';
import 'package:messenger/util/log.dart';

import '../configuration.dart';
import '../parameters/iterable_amount.dart';
import '../world/custom_world.dart';

/// Indicates whether there are the provided amount of [ChatItem]s in the opened
/// [Chat].
///
/// Examples:
/// - Then I see some messages in chat
/// - Then I see no messages in chat
final StepDefinitionGeneric
seeChatMessages = then1<IterableAmount, CustomWorld>(
  'I see {iterable_amount} messages in chat',
  (status, context) async {
    await context.world.appDriver.waitUntil(() async {
      await Future.delayed(Duration(seconds: 5));

      switch (status) {
        case IterableAmount.no:
          final noMessages = context.world.appDriver.findByKeySkipOffstage(
            'NoMessages',
          );
          final bool hasSign = await context.world.appDriver.isPresent(
            noMessages,
          );

          Log.debug(
            'seeChatMessages -> hasSign($hasSign), noMessages -> $noMessages',
            'E2E',
          );

          if (hasSign) {
            return true;
          }

          Log.debug(
            'seeChatMessages -> hasSign($hasSign), noMessages -> $noMessages',
            'E2E',
          );

          final messages = Get.find<ChatService>()
              .chats[ChatId(router.route.split('/').last)]
              ?.messages
              .map((e) => e.value)
              .whereType<ChatMessage>();

          Log.debug(
            'seeChatMessages -> messages.isEmpty(${messages?.isEmpty}), whole messages -> $messages',
            'E2E',
          );

          return messages?.isEmpty == true;

        case IterableAmount.some:
          return await context.world.appDriver.isAbsent(
            context.world.appDriver.findByKeySkipOffstage('NoMessages'),
          );
      }
    }, timeout: const Duration(seconds: 30));
  },
);

/// Indicates whether a [ChatItem] with the provided text is visible in the
/// opened [Chat].
///
/// Examples:
/// - I see "dummy message" message.
final StepDefinitionGeneric seeChatMessage = when1<String, CustomWorld>(
  'I see {string} message',
  (String text, context) async {
    final controller = Get.find<ChatController>(
      tag: router.route.split('/').last,
    );

    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle(timeout: 1.seconds);

      final ChatMessageElement? message = controller.elements.values
          .whereType<ChatMessageElement>()
          .firstWhereOrNull(
            (e) => (e.item.value as ChatMessage).text?.val == text,
          );

      return await context.world.appDriver.isPresent(
        context.world.appDriver.findByKeySkipOffstage(
          'Message_${message?.id.id}',
        ),
      );
    });
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

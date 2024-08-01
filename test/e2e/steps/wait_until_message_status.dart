// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/chat_item_quote.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';

import '../configuration.dart';
import '../parameters/sending_status.dart';
import '../world/custom_world.dart';

/// Waits until [ChatItem.status] of the specified [ChatMessage] becomes the
/// provided [MessageSentStatus].
///
/// Examples:
/// - Then I wait until status of "123" message is sending
/// - Then I wait until status of "123" message is error
/// - Then I wait until status of "123" message is sent
/// - Then I wait until status of "123" message is partially read
/// - Then I wait until status of "123" message is read
final StepDefinitionGeneric waitUntilMessageStatus =
    then2<String, MessageSentStatus, CustomWorld>(
  'I wait until status of {string} message is {sending}',
  (text, status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final RxChat? chat =
            Get.find<ChatService>().chats.values.firstWhereOrNull(
                  (e) => e.chat.value.isRoute(router.route, context.world.me),
                );

        final ChatItem? message = chat?.messages
            .map((e) => e.value)
            .whereType<ChatMessage>()
            .firstWhereOrNull((e) => e.text?.val == text);

        ChatItemId? id;

        if (message == null) {
          final forward = chat?.messages
              .map((e) => e.value)
              .whereType<ChatForward>()
              .firstWhereOrNull((e) {
            if (e.quote is ChatMessageQuote) {
              return (e.quote as ChatMessageQuote).text?.val == text;
            }

            return false;
          });

          if (forward != null) {
            final ChatController controller =
                Get.find<ChatController>(tag: chat?.id.val);

            final ListElement? element =
                controller.elements.values.firstWhereOrNull((e) {
              bool result = false;

              if (e is ChatForwardElement) {
                if (e.note.value?.value is ChatMessage) {
                  result =
                      (e.note.value?.value as ChatMessage).text?.val == text;
                }

                if (!result) {
                  result = e.forwards.any((e) {
                    if (e.value is ChatForward) {
                      if ((e.value as ChatForward).quote is ChatMessageQuote) {
                        return ((e.value as ChatForward).quote
                                    as ChatMessageQuote)
                                .text
                                ?.val ==
                            text;
                      }
                    }
                    return false;
                  });
                }
              }

              return result;
            });

            if (element != null) {
              final e = (element as ChatForwardElement);
              id = e.note.value?.value.id ?? e.forwards.first.value.id;
            }
          }
        }

        final Finder finder = context.world.appDriver
            .findByKeySkipOffstage('MessageStatus_${message?.id ?? id}');

        if (await context.world.appDriver.isPresent(finder)) {
          return context.world.appDriver.isPresent(
            context.world.appDriver.findByDescendant(
              finder,
              context.world.appDriver.findByKeySkipOffstage(switch (status) {
                MessageSentStatus.sending => 'Sending',
                MessageSentStatus.error => 'Error',
                MessageSentStatus.sent => 'Sent',
                MessageSentStatus.read => 'Read',
                MessageSentStatus.halfRead => 'HalfRead',
              }),
            ),
          );
        }

        return false;
      },
      timeout: context.configuration.timeout ?? const Duration(seconds: 30),
    );
  },
);

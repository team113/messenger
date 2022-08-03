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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../parameters/sending_status.dart';
import '../world/custom_world.dart';

/// Waits until message with provided status and text in chat with provided user
/// is present.
///
/// Examples:
/// - Then I wait until message with text "123" status is
/// sending
/// - Then I wait until message with text "123" status is error
/// - Then I wait until message with text "123" status is sent
final StepDefinitionGeneric waitUntilMessageStatus =
    then2<String, SendingStatus, CustomWorld>(
  'I wait until message with text {string} status is {sendingStatus}',
  (text, status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();
        ChatService service = Get.find();
        var chat = service.chats[ChatId(router.route.split('/').last)];
        var message = chat!.messages
            .map((e) => e.value)
            .whereType<ChatMessage>()
            .firstWhere((e) => e.text?.val == text);
        var messageFinder = context.world.appDriver
            .findByKeySkipOffstage('Message_${message.id}');

        if (await context.world.appDriver.isPresent(messageFinder)) {
          return status == SendingStatus.sending
              ? context.world.appDriver.isPresent(
                  context.world.appDriver.findByDescendant(
                      messageFinder,
                      context.world.appDriver
                          .findByKeySkipOffstage('SendingMessage')),
                )
              : status == SendingStatus.error
                  ? context.world.appDriver.isPresent(
                      context.world.appDriver.findByDescendant(
                          messageFinder,
                          context.world.appDriver
                              .findByKeySkipOffstage('ErrorMessage')),
                    )
                  : context.world.appDriver.isPresent(
                      context.world.appDriver.findByDescendant(
                          messageFinder,
                          context.world.appDriver
                              .findByKeySkipOffstage('SentMessage')),
                    );
        }

        return false;
      },
    );
  },
);

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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/sending_status.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Waits until [ChatItem.status] of the specified [ChatMessage] becomes the
/// provided [SendingStatus].
///
/// Examples:
/// - Then I wait until status of "123" message is sending
/// - Then I wait until status of "123" message is error
/// - Then I wait until status of "123" message is sent
final StepDefinitionGeneric waitUntilMessageStatus =
    then2<String, SendingStatus, CustomWorld>(
  'I wait until status of {string} message is {sending}',
  (text, status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final RxChat? chat =
            Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
        final ChatMessage message = chat!.messages
            .map((e) => e.value)
            .whereType<ChatMessage>()
            .firstWhere((e) => e.text?.val == text);

        final Finder finder = context.world.appDriver
            .findByKeySkipOffstage('MessageStatus_${message.id}');

        if (await context.world.appDriver.isPresent(finder)) {
          return status == SendingStatus.sending
              ? context.world.appDriver.isPresent(
                  context.world.appDriver.findByDescendant(
                    finder,
                    context.world.appDriver.findByKeySkipOffstage('Sending'),
                  ),
                )
              : status == SendingStatus.error
                  ? context.world.appDriver.isPresent(
                      context.world.appDriver.findByDescendant(
                        finder,
                        context.world.appDriver.findByKeySkipOffstage('Error'),
                      ),
                    )
                  : context.world.appDriver.isPresent(
                      context.world.appDriver.findByDescendant(
                        finder,
                        context.world.appDriver.findByKeySkipOffstage('Sent'),
                      ),
                    );
        }

        return false;
      },
      timeout: context.configuration.timeout ?? const Duration(seconds: 30),
    );
  },
);

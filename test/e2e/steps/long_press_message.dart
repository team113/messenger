// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/util/log.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Long presses a [ChatMessage] with the provided text in the currently opened
/// [Chat].
///
/// Examples:
/// - Then I long press "123" message
final StepDefinitionGeneric longPressMessageByText = then1<String, CustomWorld>(
  'I long press {string} message',
  (text, context) async {
    await context.world.appDriver.nativeDriver.pump(const Duration(seconds: 4));
    await context.world.appDriver.waitUntil(
      () async {
        try {
          final RxChat? chat = Get.find<ChatService>()
              .chats[ChatId(router.route.split('/').last)];

          final Iterable<ChatMessage> messages = chat!.messages
              .map((e) => e.value)
              .whereType<ChatMessage>();

          final ChatMessage? message = messages.firstWhereOrNull(
            (e) => e.text?.val == text,
          );

          Log.debug(
            'longPressMessageByText -> chat is `$chat`, message is `$message`',
            'E2E',
          );

          if (message == null) {
            Log.debug(
              'longPressMessageByText -> message is `null`, thus the whole list of messages -> $messages',
              'E2E',
            );

            return false;
          }

          final Finder finder = context.world.appDriver.findByKeySkipOffstage(
            'Message_${message.id}',
          );

          Log.debug(
            'longPressMessageByText -> finder for `Message_${message.id}` is $finder',
            'E2E',
          );

          if (finder.evaluate().isEmpty) {
            return false;
          }

          Log.debug('longPressMessageByText -> longPress()...', 'E2E');
          await context.world.appDriver.nativeDriver.longPress(finder);
          Log.debug('longPressMessageByText -> longPress()... done!', 'E2E');

          await context.world.appDriver.nativeDriver.pump(
            const Duration(seconds: 4),
          );

          return true;
        } catch (e) {
          return false;
        }
      },
      timeout: const Duration(seconds: 30),
      pollInterval: const Duration(seconds: 4),
    );
  },
);

/// Long presses a [ChatMessage] with the provided attachment attached to it in
/// the currently opened [Chat].
///
/// Examples:
/// - Then I long press message with "test.jpg"
/// - Then I long press message with "test.txt"
final StepDefinitionGeneric longPressMessageByAttachment =
    then1<String, CustomWorld>('I long press message with {string}', (
      name,
      context,
    ) async {
      await context.world.appDriver.waitForAppToSettle();

      final RxChat? chat =
          Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
      final ChatMessage message = chat!.messages
          .map((e) => e.value)
          .whereType<ChatMessage>()
          .firstWhere((e) => e.attachments.any((a) => a.filename == name));

      final Finder finder = context.world.appDriver.findByKeySkipOffstage(
        'Message_${message.id}',
      );

      await context.world.appDriver.nativeDriver.longPress(finder);
      await context.world.appDriver.waitForAppToSettle();
    });

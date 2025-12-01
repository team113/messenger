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
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart' hide Attachment;
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/util/log.dart';

import '../configuration.dart';
import '../parameters/sending_status.dart';
import '../world/custom_world.dart';

/// Waits until [LocalAttachment.status] of the specified [Attachment] becomes
/// the provided [MessageSentStatus].
///
/// Examples:
/// - Then I wait until status of "test.txt" attachment is sending
/// - Then I wait until status of "test.jpg" attachment is error
/// - Then I wait until status of "test.doc" attachment is sent
final StepDefinitionGeneric
waitUntilAttachmentStatus = then2<String, MessageSentStatus, CustomWorld>(
  'I wait until status of {string} attachment is {sending}',
  (name, status, context) async {
    await context.world.appDriver.waitUntil(() async {
      final ChatService chatService = Get.find<ChatService>();
      final RxChat? chat =
          chatService.chats[ChatId(router.route.split('/').lastOrNull ?? '')];
      final Attachment? attachment = chat?.messages
          .map((e) => e.value)
          .whereType<ChatMessage>()
          .expand((e) => e.attachments)
          .firstWhereOrNull((a) => a.filename == name);

      Log.debug(
        'waitUntilAttachmentStatus() -> last(`${router.route.split('/').last}`), thus found `$chat` in chats: ${chatService.chats}',
        'E2E',
      );

      Log.debug(
        'waitUntilAttachmentStatus() -> tried looking for attachment with filename `$name`, found: $attachment',
        'E2E',
      );

      final Iterable<String>? allAttachments = chat?.messages
          .map((e) => e.value)
          .whereType<ChatMessage>()
          .expand((e) => e.attachments)
          .map((e) => e.filename);

      Log.debug(
        'waitUntilAttachmentStatus() -> the whole list of attachments in the chat: `${allAttachments?.join(', ')}`',
        'E2E',
      );

      if (allAttachments == null || allAttachments.isEmpty) {
        Log.debug(
          'waitUntilAttachmentStatus() -> no attachments in the chat? Then the messages: `${chat?.messages.map((e) => e.value)}`',
          'E2E',
        );
      }

      final Finder finder = context.world.appDriver.findByKeySkipOffstage(
        'AttachmentStatus_${attachment?.id}',
      );

      final bool isPresent = await context.world.appDriver.isPresent(finder);

      Log.debug('waitUntilAttachmentStatus() -> isPresent = $isPresent', 'E2E');

      if (attachment != null && isPresent) {
        final String key = switch (status) {
          MessageSentStatus.sending => 'Sending',
          MessageSentStatus.error => 'Error',
          MessageSentStatus.sent => 'Sent',
          MessageSentStatus.read => 'Sent',
          MessageSentStatus.halfRead => 'Sent',
        };

        final bool isRemote = attachment is! LocalAttachment;
        final bool hasWithinMessage = await context.world.appDriver.isPresent(
          find.descendant(
            of: finder,
            matching: find.byKey(Key(key), skipOffstage: false),
            skipOffstage: false,
          ),
        );

        Log.debug(
          'waitUntilAttachmentStatus() -> looking for `$key`, hasWithinMessage -> $hasWithinMessage, isRemote -> $isRemote',
          'E2E',
        );

        final bool succeedAsRemote = switch (status) {
          MessageSentStatus.sending => true,
          MessageSentStatus.error => false,
          MessageSentStatus.sent => true,
          MessageSentStatus.read => true,
          MessageSentStatus.halfRead => true,
        };

        return hasWithinMessage || (succeedAsRemote && isRemote);
      }

      return false;
    }, timeout: context.configuration.timeout ?? const Duration(seconds: 30));
  },
);

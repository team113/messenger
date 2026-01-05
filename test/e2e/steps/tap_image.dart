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
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart' hide Attachment;
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Taps the last [ImageAttachment] in the currently opened [Chat].
///
/// Examples:
/// - Then I tap on last image in chat
final StepDefinitionGeneric tapLastImageInChat = then<CustomWorld>(
  'I tap on last image in chat',
  (context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final RxChat? chat =
          Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
      final ChatMessage? message = chat?.messages
          .map((e) => e.value)
          .whereType<ChatMessage>()
          .lastWhereOrNull(
            (e) => e.attachments.any((a) => a is ImageAttachment),
          );

      if (message == null) {
        return false;
      }

      final Attachment? attachment = message.attachments.lastWhereOrNull(
        (e) => e is ImageAttachment,
      );

      if (attachment == null) {
        return false;
      }

      final finder = context.world.appDriver.findByDescendant(
        context.world.appDriver.findByKeySkipOffstage('Message_${message.id}'),
        context.world.appDriver.findByKeySkipOffstage(
          'Attachment_${attachment.id}',
        ),
      );

      if (!finder.tryEvaluate()) {
        return false;
      }

      await context.world.appDriver.nativeDriver.tap(finder);
      await context.world.appDriver.waitForAppToSettle();

      return true;
    });
  },
);

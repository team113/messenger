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
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/chat_rx.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Taps a [ChatMessage] with the provided text in the currently opened [Chat].
///
/// Examples:
/// - Then I tap "Example" message
final StepDefinitionGeneric tapMessage = then1<String, CustomWorld>(
  'I tap {string} message',
  (text, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final RxChat? chat =
          Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
      ChatMessage? message = chat!.messages
          .map((e) => e.value)
          .whereType<ChatMessage>()
          .firstWhereOrNull((e) => e.text?.val == text);

      if (message == null) {
        final RxChatImpl rxChat = chat as RxChatImpl;
        message = rxChat.fragments
            .map((e) => e.items.values)
            .expand((e) => e)
            .map((e) => e.value)
            .whereType<ChatMessage>()
            .firstWhereOrNull((e) => e.text?.val == text);
      }

      if (message == null) {
        return false;
      }

      final Finder finder = context.world.appDriver.findByKeySkipOffstage(
        'Message_${message.id}',
      );

      await context.world.appDriver.nativeDriver.tap(
        finder,
        warnIfMissed: false,
      );
      await context.world.appDriver.waitForAppToSettle();

      return true;
    });
  },
);

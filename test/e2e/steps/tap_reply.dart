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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/chat_item_quote.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Taps a replied [ChatMessage] with the provided text in the currently opened
/// [Chat].
///
/// Examples:
/// - Then I tap "How are you?" reply of "I am fine" message
final StepDefinitionGeneric tapReply = then2<String, String, CustomWorld>(
  r'I tap {string} reply of {string} message',
  (reply, message, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final RxChat? chat =
            Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
        final ChatItemQuote quote = chat!.messages
            .map((e) => e.value)
            .whereType<ChatMessage>()
            .firstWhere((e) => e.text?.val == message)
            .repliesTo
            .firstWhere((e) => (e.original as ChatMessage).text?.val == reply);

        final Finder finder = context.world.appDriver.findByKeySkipOffstage(
          'Reply_${quote.original!.id}',
        );

        await context.world.appDriver.nativeDriver.tap(finder);

        return true;
      },
      timeout: Duration(seconds: 30),
      pollInterval: Duration(seconds: 5),
    );
  },
);

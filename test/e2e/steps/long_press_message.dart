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
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/service/chat.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Long press message in chat with provided user and text.
///
/// Examples:
/// - Then I long press message with text "123" in chat with Bob
final StepDefinitionGeneric longPressMessageByText =
    then2<String, TestUser, CustomWorld>(
  'I long press message with text {string} in chat with {user}',
  (text, user, context) async {
    await context.world.appDriver.waitForAppToSettle();
    ChatService service = Get.find();
    var chat = service.chats[context.world.sessions[user.name]!.dialog!];
    var message = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .firstWhere((e) => e.text?.val == text);
    var messageFinder =
        context.world.appDriver.findByKeySkipOffstage('Message_${message.id}');

    await context.world.appDriver.nativeDriver.longPress(messageFinder);
    await context.world.appDriver.waitForAppToSettle();
  },
);

/// Long press message in chat with provided user and text.
///
/// Examples:
/// - Then I long press message with attachment "test.jpg" in chat with Bob
/// - Then I long press message with attachment "test.txt" in chat with Bob
final StepDefinitionGeneric longPressMessageByAttachment =
    then2<String, TestUser, CustomWorld>(
  'I long press message with attachment {string} in chat with {user}',
  (name, user, context) async {
    await context.world.appDriver.waitForAppToSettle();
    ChatService service = Get.find();
    var chat = service.chats[context.world.sessions[user.name]!.dialog!];
    var message = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .firstWhere((e) => e.attachments.any((a) => a.filename == name));
    var messageFinder =
        context.world.appDriver.findByKeySkipOffstage('Message_${message.id}');

    await context.world.appDriver.nativeDriver.longPress(messageFinder);
    await context.world.appDriver.waitForAppToSettle();
  },
);

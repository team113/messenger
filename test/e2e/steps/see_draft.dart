// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Indicates whether there's any drafts containing the provided [String] in a
/// [Chat]-dialog with the specified [TestUser] on the [Chat]s tab.
///
/// Examples:
/// - Then I see draft "Message" in chat with Bob
final StepDefinitionGeneric seeDraftInDialog =
    then2<String, TestUser, CustomWorld>(
  'I see draft {string} in chat with {user}',
  (text, user, context) async {
    await context.world.appDriver.waitForAppToSettle();

    final ChatId dialog = context.world.sessions[user.name]!.dialog!;

    final Finder finder = context.world.appDriver.findByDescendant(
      context.world.appDriver.findBy('Chat_$dialog', FindType.key),
      context.world.appDriver.findBy('Draft', FindType.key),
      firstMatchOnly: true,
    );
    expect(await context.world.appDriver.isPresent(finder), true);

    final RxChat? chat = Get.find<ChatService>().chats[dialog];
    expect((chat!.draft.value as ChatMessage).text?.val, text);
  },
);

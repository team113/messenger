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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Taps a [ChatMessage] with the provided text in the currently opened [Chat].
///
/// Examples:
/// - Then I tap "Example" message
final StepDefinitionGeneric tapMessage = then1<String, CustomWorld>(
  'I tap {string} message',
  (text, context) async {
    await context.world.appDriver.waitForAppToSettle();

    final RxChat? chat =
        Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
    final ChatMessage message = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .firstWhere((e) => e.text?.val == text);

    final Finder finder =
        context.world.appDriver.findByKeySkipOffstage('Message_${message.id}');

    await context.world.appDriver.nativeDriver.tap(finder);
    await context.world.appDriver.waitForAppToSettle();
  },
);

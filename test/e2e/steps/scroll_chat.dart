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

import 'package:collection/collection.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';

/// Scrolls the currently opened [Chat] and ensures the provided number of
/// [ChatMessage]s are visible.
///
/// Examples:
/// - Then I scroll and see 1 message in chat
/// - Then I scroll and see 2 messages in chat
final StepDefinitionGeneric<FlutterWorld> scrollAndSee =
    then1<int, FlutterWorld>(
  RegExp(r'I scroll and see {int} message(s) in chat'),
  (int quantity, StepContext<FlutterWorld> context) async {
    await context.world.appDriver.waitForAppToSettle();

    final RxChat? chat =
        Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
    final Set<ChatItemId> ids = {};

    await context.world.appDriver.scrollUntilVisible(
      find.byWidgetPredicate(
        (Widget widget) {
          if (widget is ChatItemWidget) {
            final ChatItem item = widget.item.value;
            if (item is ChatMessage) {
              ids.add(item.id);
              if (item.id == chat?.messages.lastOrNull?.value.id) {
                return true;
              }
            }
          }
          return false;
        },
        skipOffstage: false,
      ),
      scrollable: find.descendant(
        of: find.byKey(const Key('MessagesList')),
        matching: find.byType(Scrollable),
      ),
      dy: 100,
    );

    await context.world.appDriver.waitForAppToSettle();

    expect(ids.length, quantity);
  },
);

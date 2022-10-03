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

import 'package:flutter/material.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/routes.dart';

/// Indicates whether the provided number of specific [Widget]s are visible.
///
/// Examples:
/// - Then I expect to see 1 `ChatMessage`
final StepDefinitionGeneric<FlutterWorld> expectNWidget =
    then1<int, FlutterWorld>(
  RegExp(r'I expect to see {int} message(s) in chat'),
  (int quantity, StepContext<FlutterWorld> context) async {
    await context.world.appDriver.waitForAppToSettle();
    const double delta = 100;
    final Set<String> quantityMessages = {};
    final RxChat? chat =
        Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
    final String? lastItemId = chat?.chat.value.lastItem?.id.val;

    await context.world.appDriver.scrollUntilVisible(
      find.byWidgetPredicate(
        (Widget widget) {
          if (widget is ChatItemWidget) {
            final ChatItem chatItem = widget.item.value;
            if (chatItem is ChatMessage) {
              quantityMessages.add(chatItem.id.val);
              if ((widget.key as ValueKey<String>).value == lastItemId) {
                return true;
              }
            }
          }
          return false;
        },
        skipOffstage: false,
      ),
      scrollable: find.descendant(
        of: find.byType(FlutterListView),
        matching: find.byType(Scrollable),
      ),
      dy: -delta,
    );
    await context.world.appDriver.waitForAppToSettle();
    expect(quantityMessages.length, quantity);
  },
);

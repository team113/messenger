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
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/ui/page/home/tab/chats/controller.dart';

import '../parameters/position_status.dart';
import '../world/custom_world.dart';

/// Indicates whether [Chat] with the specified name is displayed at the
/// specified [PositionStatus].
final StepDefinitionGeneric seeChatAsPosition =
    then2<String, PositionStatus, CustomWorld>(
  'I see {string} chat as {position} in chats list',
  (name, status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final controller = Get.find<ChatsTabController>();
        final ChatId chatId = context.world.groups[name]!;

        switch (status) {
          case PositionStatus.first:
            return controller.chats.first.id == chatId;
          case PositionStatus.last:
            return controller.chats.last.id == chatId;
        }
      },
    );
  },
);

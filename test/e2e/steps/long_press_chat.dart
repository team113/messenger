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

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/service/chat.dart';

import '../world/custom_world.dart';

/// Long presses a [Chat] with the provided name.
///
/// Examples:
/// - When I long press "Name" chat
final StepDefinitionGeneric longPressChat = when1<String, CustomWorld>(
  'I long press {string} (?:chat|group)',
  (name, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      try {
        final finder = context.world.appDriver
            .findBy('Chat_${context.world.groups[name]}', FindType.key)
            .first;

        await context.world.appDriver.nativeDriver.longPress(finder);
        await context.world.appDriver.waitForAppToSettle();

        return true;
      } catch (e) {
        return false;
      }
    });
  },
);

/// Long presses a [Chat]-monolog.
///
/// Examples:
/// - When I long press monolog.
final StepDefinitionGeneric longPressMonolog = when<CustomWorld>(
  'I long press monolog',
  (context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final ChatId chatId = Get.find<ChatService>().monolog;

      try {
        final finder = context.world.appDriver
            .findBy('Chat_$chatId', FindType.key)
            .first;

        await context.world.appDriver.nativeDriver.longPress(finder);
        await context.world.appDriver.waitForAppToSettle();

        return true;
      } catch (e) {
        return false;
      }
    });
  },
);

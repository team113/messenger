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
import 'package:messenger/util/log.dart';

import '../world/custom_world.dart';

/// Long presses a [Chat] with the provided name.
///
/// Examples:
/// - When I long press "Name" chat
final StepDefinitionGeneric longPressChat = when1<String, CustomWorld>(
  'I long press {string} (?:chat|group)',
  (name, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.nativeDriver.pump(
          const Duration(seconds: 5),
        );

        try {
          final finder = context.world.appDriver.findBy(
            'Chat_${context.world.groups[name]}',
            FindType.key,
          );

          Log.debug(
            'longPressChat -> finder for `Chat_${context.world.groups['name']}` is `$finder`',
          );

          if (finder.evaluate().isNotEmpty) {
            Log.debug('longPressChat -> await longPress()...');
            await context.world.appDriver.nativeDriver.longPress(finder);
            Log.debug('longPressChat -> await longPress()... done!');

            await context.world.appDriver.nativeDriver.pump(
              const Duration(seconds: 5),
            );

            return true;
          }

          return false;
        } catch (e) {
          Log.debug('longPressChat -> caught $e', 'E2E');
          return false;
        }
      },
      timeout: const Duration(seconds: 60),
      pollInterval: const Duration(seconds: 2),
    );
  },
);

/// Long presses a [Chat]-monolog.
///
/// Examples:
/// - When I long press monolog.
final StepDefinitionGeneric
longPressMonolog = when<CustomWorld>('I long press monolog', (context) async {
  await context.world.appDriver.waitUntil(() async {
    Log.debug('longPressMonolog -> await pump()...', 'E2E');

    await context.world.appDriver.nativeDriver.pump(const Duration(seconds: 3));

    Log.debug('longPressMonolog -> await pump()... done!', 'E2E');

    final ChatId chatId = Get.find<ChatService>().monolog;

    try {
      final finder = context.world.appDriver
          .findBy('Chat_$chatId', FindType.key)
          .first;

      Log.debug('longPressMonolog -> finder for `$chatId` is $finder', 'E2E');

      Log.debug('longPressMonolog -> await longPress()...', 'E2E');
      await context.world.appDriver.nativeDriver.longPress(finder);
      Log.debug('longPressMonolog -> await longPress()... done!', 'E2E');

      await context.world.appDriver.nativeDriver.pump(
        const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      Log.debug('longPressMonolog -> caught $e', 'E2E');
      Log.debug(
        'longPressMonolog -> the whole paginated list -> ${Get.find<ChatService>().paginated.values}',
        'E2E',
      );
      Log.debug(
        'longPressMonolog -> the whole chats list -> ${Get.find<ChatService>().chats.values}',
        'E2E',
      );

      return false;
    }
  }, timeout: const Duration(seconds: 30));
});

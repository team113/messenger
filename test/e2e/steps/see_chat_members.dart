// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/page/user/controller.dart';
import 'package:messenger/util/log.dart';

import '../world/custom_world.dart';

/// Waits until the [Chat.members] count is indeed the provided count.
///
/// Examples:
/// - Then I see 15 chat members
final StepDefinitionGeneric seeChatMembers = then1<int, CustomWorld>(
  RegExp(r'I see {int} chat members'),
  (int count, context) async {
    await context.world.appDriver.waitUntil(() async {
      Log.debug(
        'seeChatMembers -> await context.world.appDriver.waitForAppToSettle()...',
        'E2E',
      );

      await context.world.appDriver.waitForAppToSettle();

      Log.debug(
        'seeChatMembers -> await context.world.appDriver.waitForAppToSettle()... done!',
        'E2E',
      );

      final RxChat? chat =
          Get.find<ChatService>().chats[ChatId(router.route.split('/')[2])];

      Log.debug(
        'seeChatMembers -> chat($chat), members: ${chat?.members.length} vs $count vs ${chat?.chat.value.members.length}',
        'E2E',
      );

      Log.debug(
        'seeChatMembers -> the whole members list: ${chat?.members.values.map((e) => e.user.title())}',
        'E2E',
      );

      return (chat?.members.length ?? 0) >= count ||
          (chat?.chat.value.members.length ?? 0) >= count;
    }, timeout: const Duration(seconds: 60));
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

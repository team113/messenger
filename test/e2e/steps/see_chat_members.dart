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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../world/custom_world.dart';

/// Waits until the [Chat.members] count is indeed the provided count.
///
/// Examples:
/// - Then I see 15 chat members
final StepDefinitionGeneric seeChatMembers = then1<int, CustomWorld>(
  RegExp(r'I see {int} chat members'),
  (int count, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final RxChat? chat =
          Get.find<ChatService>().chats[ChatId(router.route.split('/')[2])];

      return chat?.members.length == count;
    });
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

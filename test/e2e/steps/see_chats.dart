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
import 'package:messenger/ui/page/home/tab/chats/controller.dart';

import '../world/custom_world.dart';

/// Indicates whether the provided count of [Chat]s are present within
/// [ChatsTabView].
///
/// Examples:
/// - Then I see 30 chats
final StepDefinitionGeneric seeCountChats = then1<int, CustomWorld>(
  'I see {int} chats\$',
  (count, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle(timeout: 1.seconds);

      final controller = Get.find<ChatsTabController>();

      final Iterable<ChatEntry> chats = controller.chats.where((e) {
        final bool notLocalOrHasMessages =
            !e.id.isLocal || e.messages.isNotEmpty || e.chat.value.isMonolog;

        return notLocalOrHasMessages &&
            !e.chat.value.isHidden &&
            !e.chat.value.isArchived;
      });

      return chats.length == count;
    }, timeout: const Duration(seconds: 60));
  },
);

/// Indicates whether the provided count (or more) of [Chat]s are present within
/// [ChatsTabView].
///
/// Examples:
/// - Then I see 30 or more chats
final StepDefinitionGeneric seeCountChatsOrMore = then1<int, CustomWorld>(
  'I see {int} or more chats\$',
  (count, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle(timeout: 1.seconds);

      final controller = Get.find<ChatsTabController>();

      final Iterable<ChatEntry> chats = controller.chats.where((e) {
        final bool notLocalOrHasMessages =
            !e.id.isLocal || e.messages.isNotEmpty || e.chat.value.isMonolog;

        return notLocalOrHasMessages &&
            !e.chat.value.isHidden &&
            !e.chat.value.isArchived;
      });

      return chats.length >= count;
    }, timeout: const Duration(seconds: 60));
  },
);

/// Indicates whether the provided count of favorite [Chat]s are present within
/// [ChatsTabView].
///
/// Examples:
/// - Then I see 30 favorite chats
final StepDefinitionGeneric seeCountFavoriteChats = then1<int, CustomWorld>(
  'I see {int} favorite chats',
  (count, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle(timeout: 1.seconds);

      final controller = Get.find<ChatsTabController>();
      final length = controller.chats.where((e) {
        final bool notLocalOrHasMessages =
            !e.id.isLocal || e.messages.isNotEmpty || e.chat.value.isMonolog;

        final bool notHidden =
            notLocalOrHasMessages &&
            !e.chat.value.isHidden &&
            !e.chat.value.isArchived;

        return notHidden && e.chat.value.favoritePosition != null;
      }).length;

      return length == count;
    }, timeout: const Duration(seconds: 30));
  },
);

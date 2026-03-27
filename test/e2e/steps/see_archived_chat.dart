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
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/util/log.dart';

import '../configuration.dart';
import '../parameters/archived_status.dart';
import '../world/custom_world.dart';

/// Indicates whether a [Chat] with the provided name is displayed with the
/// specified [ArchivedStatus].
///
/// Examples:
/// - Then I see "Example" chat as archived
/// - Then I see "Example" group as unarchived
final StepDefinitionGeneric
seeChatAsArchived = then2<String, ArchivedStatus, CustomWorld>(
  'I see {string} (?:chat|group) as {archived}',
  (name, status, context) async {
    await context.world.appDriver.waitUntil(() async {
      final ChatId chatId = context.world.groups[name]!;

      final bool inArchive = context.world.appDriver
          .findByKeySkipOffstage('ArchivedChats')
          .evaluate()
          .isNotEmpty;

      Log.debug(
        'seeChatAsArchived -> $chatId, inArchive? $inArchive -> ${context.world.appDriver.findByKeySkipOffstage('ArchivedChats')}',
        'E2E',
      );

      switch (status) {
        case ArchivedStatus.archived:
          final finder = context.world.appDriver.findByKeySkipOffstage(
            '$chatId',
          );

          Log.debug(
            'seeChatAsArchived -> inArchive -> looking for `$chatId` -> $finder',
            'E2E',
          );

          final isPresent = inArchive && finder.evaluate().isNotEmpty;

          if (!isPresent) {
            final ChatService chatService = Get.find<ChatService>();
            Log.debug(
              'seeChatAsArchived -> seems like `isPresent` is `false`, thus the whole archive list: ${chatService.archived.values.toList()}',
              'E2E',
            );

            Log.debug(
              'seeChatAsArchived -> and whole chats list: ${chatService.paginated.values.toList()}',
              'E2E',
            );
          }

          return isPresent;

        case ArchivedStatus.unarchived:
          final finder = context.world.appDriver.findByKeySkipOffstage(
            '$chatId',
          );

          Log.debug(
            'seeChatAsArchived -> !inArchive -> looking for `$chatId` -> $finder',
            'E2E',
          );

          final isPresent = !inArchive && finder.evaluate().isNotEmpty;

          if (!isPresent) {
            final ChatService chatService = Get.find<ChatService>();
            Log.debug(
              'seeChatAsArchived -> seems like `isPresent` is `false`, thus the whole chats list: ${chatService.paginated.values.toList()}',
              'E2E',
            );

            Log.debug(
              'seeChatAsArchived -> and whole archived list: ${chatService.archived.values.toList()}',
              'E2E',
            );
          }

          return isPresent;
      }
    }, timeout: const Duration(seconds: 30));
  },
);

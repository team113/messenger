// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart' hide Attachment;
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/worker/cache.dart';
import 'package:messenger/util/log.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Waits until [FileAttachment.downloadStatus] of the specified
/// [FileAttachment] becomes the provided [DownloadStatus].
///
/// Examples:
/// - Then I wait until "test.txt" file is not downloaded
/// - Then I wait until "test.pdf" file is downloading
/// - Then I wait until "test.doc" file is downloaded
final StepDefinitionGeneric
waitUntilFileStatus = then2<String, DownloadStatus, CustomWorld>(
  'I wait until {string} file is {downloadStatus}',
  (name, status, context) async {
    await context.world.appDriver.waitUntil(() async {
      final ChatService chatService = Get.find<ChatService>();
      final RxChat? chat =
          chatService.chats[ChatId(router.route.split('/').last)];
      final Attachment? attachment = chat?.messages
          .map((e) => e.value)
          .whereType<ChatMessage>()
          .expand((e) => e.attachments)
          .firstWhereOrNull((a) => a.filename == name);

      Log.debug(
        'waitUntilFileStatus() -> last(`${router.route.split('/').last}`), thus found `$chat` in chats: ${chatService.chats}',
        'E2E',
      );

      Log.debug(
        'waitUntilFileStatus() -> tried looking for attachment with filename `$name`, found: $attachment',
        'E2E',
      );

      Log.debug(
        'waitUntilFileStatus() -> the whole list of attachments in the chat: `${chat?.messages.map((e) => e.value).whereType<ChatMessage>().expand((e) => e.attachments).map((e) => e.filename).join(', ')}`',
        'E2E',
      );

      final Finder finder = context.world.appDriver.findByKeySkipOffstage(
        'File_${attachment?.id}',
      );

      final bool isPresent = await context.world.appDriver.isPresent(finder);

      Log.debug('waitUntilFileStatus() -> isPresent = $isPresent', 'E2E');

      if (attachment != null && isPresent) {
        final String key = switch (status) {
          DownloadStatus.notStarted => 'Download',
          DownloadStatus.inProgress => 'Downloading',
          DownloadStatus.isFinished => 'Downloaded',
        };

        final bool hasWithinFile = await context.world.appDriver.isPresent(
          context.world.appDriver.findByDescendant(
            finder,
            context.world.appDriver.findByKeySkipOffstage(key),
            firstMatchOnly: true,
          ),
        );

        Log.debug(
          'waitUntilFileStatus() -> looking for `$key`, hasWithinFile -> $hasWithinFile',
          'E2E',
        );

        if (!hasWithinFile && status == DownloadStatus.inProgress) {
          // File might've already downloaded, thus when expecting in progress
          // status, we should also check for downloaded one.
          return await context.world.appDriver.isPresent(
            context.world.appDriver.findByDescendant(
              finder,
              context.world.appDriver.findByKeySkipOffstage('Downloaded'),
              firstMatchOnly: true,
            ),
          );
        }

        return hasWithinFile;
      }

      return false;
    }, timeout: context.configuration.timeout ?? const Duration(seconds: 30));
  },
);

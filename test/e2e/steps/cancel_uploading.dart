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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart' hide Attachment;
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/util/log.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Cancels uploading of a [FileAttachment] with the provided name in the
/// currently opened [Chat].
///
/// Examples:
/// - And I cancel "test.txt" file upload
final StepDefinitionGeneric
cancelFileUpload = then1<String, CustomWorld>('I cancel {string} file upload', (
  String fileName,
  context,
) async {
  await context.world.appDriver.waitUntil(() async {
    await context.world.appDriver.waitForAppToSettle();

    final RxChat? chat = Get.find<ChatService>()
        .chats[ChatId(router.route.split('/').lastOrNull ?? '')];

    Log.debug('cancelFileUpload -> chat is $chat', 'E2E');

    final Iterable<ChatMessage> messages = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>();

    final Iterable<Attachment> attachments = messages.expand(
      (e) => e.attachments,
    );

    final Attachment? attachment = attachments.firstWhereOrNull(
      (a) => a.filename == fileName,
    );

    Log.debug('cancelFileUpload -> attachment is $attachment', 'E2E');

    if (attachment == null) {
      Log.debug(
        'cancelFileUpload -> it seems that no attachments were found, thus the whole attachment list: $attachments',
        'E2E',
      );

      Log.debug(
        'cancelFileUpload -> and the whole messages list: $messages',
        'E2E',
      );

      return false;
    }

    final fileFinder = context.world.appDriver.findByKeySkipOffstage(
      'File_${attachment.id}',
    );

    final cancelButton = context.world.appDriver.findByDescendant(
      fileFinder,
      context.world.appDriver.findByKeySkipOffstage('CancelUploading'),
    );

    Log.debug(
      'cancelFileUpload -> looking for `File_${attachment.id}` -> $fileFinder',
      'E2E',
    );

    Log.debug(
      'cancelFileUpload -> looking for `CancelUploading` within `File_${attachment.id}` -> $cancelButton',
      'E2E',
    );

    Log.debug(
      'cancelFileUpload -> all `CancelUploading` present in the tree: ${context.world.appDriver.findByKeySkipOffstage('CancelUploading')}',
      'E2E',
    );

    await context.world.appDriver.nativeDriver.tap(cancelButton);

    return true;
  }, timeout: const Duration(seconds: 30));
});

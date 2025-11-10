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
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart' hide Attachment;
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Cancels uploading of a [FileAttachment] with the provided name in the
/// currently opened [Chat].
///
/// Examples:
/// - And I cancel "test.txt" file upload
final StepDefinitionGeneric cancelFileUpload = then1<String, CustomWorld>(
  'I cancel {string} file upload',
  (String fileName, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final RxChat? chat = Get.find<ChatService>()
          .chats[ChatId(router.route.split('/').lastOrNull ?? '')];

      final Attachment? attachment = chat!.messages
          .map((e) => e.value)
          .whereType<ChatMessage>()
          .expand((e) => e.attachments)
          .firstWhereOrNull((a) => a.filename == fileName);

      if (attachment == null) {
        return false;
      }

      final cancelButton = context.world.appDriver.findByDescendant(
        context.world.appDriver.findByKeySkipOffstage('File_${attachment.id}'),
        context.world.appDriver.findByKeySkipOffstage('CancelUploading'),
      );

      await context.world.appDriver.nativeDriver.tap(cancelButton);

      return true;
    }, timeout: const Duration(seconds: 30));
  },
);

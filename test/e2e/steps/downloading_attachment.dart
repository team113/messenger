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
import 'package:gherkin/gherkin.dart' hide Attachment;
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Marks attachment with the given filename as downloading.
///
/// Examples:
/// - Then I start downloading "test.txt" attachment in chat with Bob
StepDefinitionGeneric startDownloading = then2<String, TestUser, CustomWorld>(
  'I start downloading {string} attachment in chat with {user}',
  (name, user, context) async {
    var chatId = context.world.sessions[user.name]?.dialog;
    AbstractChatRepository chatRepo = Get.find();
    Attachment attachment = chatRepo.chats[chatId]!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .expand((e) => e.attachments)
        .firstWhere((e) => e.filename == name);
    (attachment as FileAttachment).downloading.value =
        DownloadingStatus.downloading;
  },
);

/// Marks attachment with the given filename as downloaded.
///
/// Examples:
/// - Then I finish downloading "test.txt" attachment in chat with Bob
StepDefinitionGeneric finishDownloading = then2<String, TestUser, CustomWorld>(
  'I finish downloading {string} attachment in chat with {user}',
  (name, user, context) async {
    var chatId = context.world.sessions[user.name]?.dialog;
    AbstractChatRepository chatRepo = Get.find();
    Attachment attachment = chatRepo.chats[chatId]!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .expand((e) => e.attachments)
        .firstWhere((e) => e.filename == name);
    (attachment as FileAttachment).downloading.value =
        DownloadingStatus.downloaded;
  },
);

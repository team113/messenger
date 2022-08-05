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

import 'package:flutter_test/flutter_test.dart';
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

/// Presses a download button of the [FileAttachment] with provided name in the
/// currently opened [Chat].
///
/// Examples:
/// - Then I start downloading "test.txt" file
/// - Then I start downloading "test.pdf" file
/// - Then I start downloading "test.doc" file
final StepDefinitionGeneric startDownloadFile = then1<String, CustomWorld>(
  'I start downloading {string} file',
  (name, context) async {
    await context.world.appDriver.waitForAppToSettle();

    RxChat? chat =
        Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
    Attachment attachment = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .expand((e) => e.attachments)
        .firstWhere((a) => a.filename == name);

    Finder finder =
        context.world.appDriver.findByKeySkipOffstage('File_${attachment.id}');
    Finder downloadButton = context.world.appDriver.findByDescendant(
      finder,
      context.world.appDriver.findByKeySkipOffstage('Download'),
    );

    await context.world.appDriver.nativeDriver.tap(downloadButton);
  },
);

/// Presses a cancel download button of the [FileAttachment] with provided name
/// in the currently opened [Chat].
///
/// Examples:
/// - Then I cancel downloading "test.txt" file
/// - Then I cancel downloading "test.pdf" file
/// - Then I cancel downloading "test.doc" file
final StepDefinitionGeneric cancelDownloadFile = then1<String, CustomWorld>(
  'I cancel downloading {string} file',
  (name, context) async {
    await context.world.appDriver.waitForAppToSettle();

    RxChat? chat =
        Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
    Attachment attachment = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .expand((e) => e.attachments)
        .firstWhere((a) => a.filename == name);

    Finder finder =
        context.world.appDriver.findByKeySkipOffstage('File_${attachment.id}');
    Finder cancelButton = context.world.appDriver.findByDescendant(
      finder,
      context.world.appDriver.findByKeySkipOffstage('CancelDownloading'),
    );

    await context.world.appDriver.nativeDriver.tap(cancelButton);
  },
);

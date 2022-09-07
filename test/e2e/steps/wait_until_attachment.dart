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

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_gherkin/src/flutter/parameters/existence_parameter.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart' hide Attachment;
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

/// Waits until the [Attachment] with provided [Attachment.filename] is present
/// or absent.
///
/// Examples:
/// - Then I wait until attachment "test.txt" is absent
/// - Then I wait until attachment "test.jpg" is present
final StepDefinitionGeneric untilAttachmentExists =
    then2<String, Existence, FlutterWorld>(
  'I wait until attachment {string} is {existence}',
  (filename, existence, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final RxChat? chat =
            Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];

        bool exist = chat!.messages
            .map((m) => m.value)
            .whereType<ChatMessage>()
            .any((m) => m.attachments.any((a) => a.filename == filename));

        switch (existence) {
          case Existence.present:
            return exist;

          case Existence.absent:
            return !exist;
        }
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

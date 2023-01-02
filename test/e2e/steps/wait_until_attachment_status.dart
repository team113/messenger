// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'package:messenger/domain/model/sending_status.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Waits until [LocalAttachment.status] of the specified [Attachment] becomes
/// the provided [SendingStatus].
///
/// Examples:
/// - Then I wait until status of "test.txt" attachment is sending
/// - Then I wait until status of "test.jpg" attachment is error
/// - Then I wait until status of "test.doc" attachment is sent
final StepDefinitionGeneric waitUntilAttachmentStatus =
    then2<String, SendingStatus, CustomWorld>(
  'I wait until status of {string} attachment is {sending}',
  (name, status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        RxChat? chat =
            Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
        Attachment attachment = chat!.messages
            .map((e) => e.value)
            .whereType<ChatMessage>()
            .expand((e) => e.attachments)
            .firstWhere((a) => a.filename == name);

        Finder finder = context.world.appDriver
            .findByKeySkipOffstage('AttachmentStatus_${attachment.id}');

        if (await context.world.appDriver.isPresent(finder)) {
          return status == SendingStatus.sending
              ? context.world.appDriver.isPresent(
                  context.world.appDriver.findByDescendant(
                    finder,
                    context.world.appDriver.findByKeySkipOffstage('Sending'),
                  ),
                )
              : status == SendingStatus.error
                  ? context.world.appDriver.isPresent(
                      context.world.appDriver.findByDescendant(
                        finder,
                        context.world.appDriver.findByKeySkipOffstage('Error'),
                      ),
                    )
                  : context.world.appDriver.isPresent(
                      context.world.appDriver.findByDescendant(
                        finder,
                        context.world.appDriver.findByKeySkipOffstage('Sent'),
                      ),
                    );
        }

        return false;
      },
      timeout: context.configuration.timeout ?? const Duration(seconds: 30),
    );
  },
);

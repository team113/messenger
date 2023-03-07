// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart' hide Attachment;
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../parameters/fetch_status.dart';

/// Waits until the specified image attachment is fetched or is being fetched.
///
/// Examples:
/// - Then I wait until "test.jpg" attachment is fetching
/// - Then I wait until "test.jpg" attachment is fetched
final StepDefinitionGeneric untilAttachmentFetched =
    then2<String, ImageFetchStatus, FlutterWorld>(
  'I wait until {string} attachment is {fetch_status}',
  (filename, status, context) async {
    final RxChat? chat =
        Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];

    await context.world.appDriver.waitUntil(
      () async {
        final Attachment? attachment;

        attachment = chat!.messages
            .map((e) => e.value)
            .whereType<ChatMessage>()
            .expand((e) => e.attachments)
            .firstWhereOrNull((a) => a.filename == filename);

        if (attachment == null) {
          return false;
        }

        return context.world.appDriver.isPresent(
          context.world.appDriver.findByDescendant(
            context.world.appDriver.findByKeySkipOffstage(
              'Image_${(attachment as ImageAttachment).big.url}',
            ),
            context.world.appDriver.findByKeySkipOffstage(
              status == ImageFetchStatus.fetching ? 'Loading' : 'Loaded',
            ),
            firstMatchOnly: true,
          ),
        );
      },
      pollInterval: const Duration(milliseconds: 1),
      timeout: const Duration(seconds: 60),
    );
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 60),
);

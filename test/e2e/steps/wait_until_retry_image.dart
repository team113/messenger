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
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart' hide Attachment;
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../parameters/retry_image.dart';

/// Waits until the image is present or absent.
///
/// Examples:
/// - Then I wait until image "test.jpg" is loading
/// - Then I wait until image "test.jpg" is loaded
final StepDefinitionGeneric waitUntilImage =
    then2<String, RetryImageStatus, FlutterWorld>(
  'I wait until image {string} is {retry_status}',
  (fileName, status, context) async {
    RxChat? chat =
        Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
    Attachment attachment;
    await context.world.appDriver.waitUntil(
      () async {
        try {
          attachment = chat!.messages
              .map((e) => e.value)
              .whereType<ChatMessage>()
              .expand((e) => e.attachments)
              .firstWhere((a) => a.filename == fileName);
        } catch (e) {
          return false;
        }
        return status == RetryImageStatus.loading
            ? context.world.appDriver.isPresent(
                context.world.appDriver.findByKeySkipOffstage(
                    'RetryImageLoading${(attachment as ImageAttachment).big.url}'),
              )
            : context.world.appDriver.isPresent(
                context.world.appDriver.findByKeySkipOffstage(
                    'RetryImageLoaded${(attachment as ImageAttachment).big.url}'),
              );
      },
      pollInterval: const Duration(milliseconds: 1),
      timeout: const Duration(seconds: 60),
    );
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 60),
);

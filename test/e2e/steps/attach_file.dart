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

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';
import 'package:messenger/ui/page/home/page/chat/forward/controller.dart';

import '../parameters/attachment.dart';
import '../world/custom_world.dart';

/// Attaches an [Attachment] with the provided filename and [AttachmentType] to
/// the currently opened [Chat].
///
/// Examples:
/// - Then I attach "test.txt" file
/// - Then I attach "test.png" image
final StepDefinitionGeneric attachFile =
    then2<String, AttachmentType, CustomWorld>(
  'I attach {string} {attachment}\$',
  (name, attachmentType, context) async {
    await context.world.appDriver.waitForAppToSettle();

    final ChatController chat =
        Get.find<ChatController>(tag: router.route.split('/').last);

    _attachFile(attachmentType, name, chat.addPlatformAttachment);
  },
);

/// Attaches an [Attachment] with the provided filename and [AttachmentType] to
/// the currently opened [ChatForwardView].
///
/// Examples:
/// - Then I attach "test.txt" file to forwards
/// - Then I attach "test.png" image to forwards
final StepDefinitionGeneric attachFileToForwards =
    then2<String, AttachmentType, CustomWorld>(
  'I attach {string} {attachment} to forwards',
  (name, attachmentType, context) async {
    await context.world.appDriver.waitForAppToSettle();

    final ChatForwardController chat = Get.find<ChatForwardController>();

    _attachFile(attachmentType, name, chat.addPlatformAttachment);
  },
);

/// Calls the [callback] due to provided parameters to attach the file.
void _attachFile(AttachmentType attachmentType, String name,
    Function(PlatformFile) callback) {
  if (attachmentType == AttachmentType.file) {
    callback(
      PlatformFile(
        name: name,
        size: 2,
        bytes: Uint8List.fromList([1, 1]),
      ),
    );
  } else {
    callback(
      PlatformFile(
        name: name,
        size: 2,
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
        ),
      ),
    );
  }
}

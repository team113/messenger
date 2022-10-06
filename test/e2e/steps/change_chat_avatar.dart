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

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/ui/page/home/page/chat/info/controller.dart';

import '../world/custom_world.dart';

/// Change chat avatar in chat specified by name.
///
/// Examples:
/// - Then I am change chat avatar inside chat 'Chat name'
final StepDefinitionGeneric changeChatAvatar = then1<String, CustomWorld>(
  'I am change chat avatar inside chat {string}',
  (chatName, context) async {
    final PlatformFile image = PlatformFile(
      name: 'test',
      size: 2,
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );

    ChatId chatId = context.world.groupChats[chatName]!;
    if (Get.isRegistered<ChatInfoController>(tag: 'ChatInfo$chatId')) {
      final controller = Get.find<ChatInfoController>(tag: 'ChatInfo$chatId');
      await controller.updateChatAvatar(image);
    }
  },
);

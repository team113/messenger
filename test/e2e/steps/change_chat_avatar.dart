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
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/page/chat/info/controller.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Routes the [router] to the [Chat]-dialog page with the provided [TestUser].
///
/// Examples:
/// - Given I am in chat with Bob
final StepDefinitionGeneric changeChatAvatar = given<CustomWorld>(
  'I am change chat avatar',
  (context) async {
    final PlatformFile image = PlatformFile(
      name: 'test',
      size: 2,
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );

    print('1');
    if (Get.isRegistered<ChatInfoController>()) {
      print('2');
      final controller = Get.find<ChatInfoController>();
      await controller.updateChatAvatar(image);
      print('3');
    }
  },
);

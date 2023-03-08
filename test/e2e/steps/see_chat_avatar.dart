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

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/avatar.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../world/custom_world.dart';

/// Waits until the [ChatAvatar] being displayed is indeed the provided image.
///
/// Examples:
/// - Then I see chat avatar as "test.jpg"
final StepDefinitionGeneric seeChatAvatarAs = then1<String, CustomWorld>(
  RegExp(r'I see chat avatar as {string}'),
  (String filename, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final RxChat? chat =
            Get.find<ChatService>().chats[ChatId(router.route.split('/')[2])];

        final finder = context.world.appDriver.findByDescendant(
          context.world.appDriver
              .findBy('ChatAvatar_${chat?.id}', FindType.key),
          context.world.appDriver.findBy(
            'Image_${chat?.avatar.value?.original.url}',
            FindType.key,
          ),
          firstMatchOnly: true,
        );

        return context.world.appDriver.isPresent(finder);
      },
    );
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Waits until the [ChatAvatar] being displayed has no image in it.
///
/// Examples:
/// - Then I see chat avatar as none
final StepDefinitionGeneric seeChatAvatarAsNone = then<CustomWorld>(
  RegExp(r'I see chat avatar as none'),
  (context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final RxChat? chat =
            Get.find<ChatService>().chats[ChatId(router.route.split('/')[2])];

        if (chat?.avatar.value == null) {
          final finder = context.world.appDriver
              .findBy('ChatAvatar_${chat?.id}', FindType.key);
          return context.world.appDriver.isPresent(finder);
        }

        return false;
      },
    );
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

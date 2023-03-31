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

import 'package:get/get.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';

import '../world/custom_world.dart';

/// Routes the [router] to the [Chat]-monolog page.
///
/// Examples:
/// - I am in monolog
final StepDefinitionGeneric iAmInChatMonolog = given<CustomWorld>(
  'I am in monolog',
  (context) async {
    final ChatService chatService = Get.find<ChatService>();
    router.chat(chatService.monolog!);

    await context.world.appDriver.waitUntil(
      () async {
        return context.world.appDriver.isPresent(
          context.world.appDriver.findBy('ChatView', FindType.key),
        );
      },
    );
  },
);

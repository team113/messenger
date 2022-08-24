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
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Selects the chats to forward messages inside the [ChatForwardView].
///
/// Examples:
/// - Then I select chat with Bob to forward
/// - Then I select chat with Charlie to forward
final StepDefinitionGeneric selectChatToForward = then1<TestUser, CustomWorld>(
  'I select chat with {user} to forward',
  (user, context) async {
    await context.world.appDriver.waitForAppToSettle();

    RxChat? chat = await Get.find<ChatService>()
        .get(context.world.sessions[user.name]!.dialog!);

    Finder finder = context.world.appDriver
        .findByKeySkipOffstage('ChatForwardTile_${chat!.chat.value.id}');

    await context.world.appDriver.tap(finder);
    await context.world.appDriver.waitForAppToSettle();
  },
);

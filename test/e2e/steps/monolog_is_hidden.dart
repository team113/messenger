// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/service/chat.dart';

import '../world/custom_world.dart';

//// Indicates whether a dialog [Chat] with the provided name is not displayed
/// in the list of chats.
///
/// The [Chat] object represents a dialog between users.Add commentMore actions
///
/// Examples:
/// - Then I see no dialog with "Bob"
final StepDefinitionGeneric monologIsHidden = then<CustomWorld>(
  'Monolog is indeed hidden',
  (context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final chatService = Get.find<ChatService>();
      final monolog = await chatService.get(chatService.monolog);

      return monolog?.chat.value.isHidden == true;
    });
  },
);

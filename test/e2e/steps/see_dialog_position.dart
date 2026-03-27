// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/ui/page/home/tab/chats/controller.dart';

import '../parameters/position_status.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Indicates whether a dialog [Chat]-dialog with the provided name is displayed
/// at the specified [PositionStatus].
///
/// Examples:
/// - Then I see dialog with Bob first in favorites list
/// - Then I see dialog with Bob last in favorites list
final StepDefinitionGeneric seeFavoriteDialogPosition =
    then2<TestUser, PositionStatus, CustomWorld>(
      'I see dialog with {user} {position} in favorites list',
      (user, status, context) async {
        await context.world.appDriver.waitUntil(() async {
          await context.world.appDriver.waitForAppToSettle();

          final ChatsTabController controller = Get.find<ChatsTabController>();
          final ChatId chatId = context.world.sessions[user.name]!.dialog!;
          final Iterable<ChatEntry> favorites = controller.chats.where(
            (c) => c.chat.value.favoritePosition != null,
          );

          switch (status) {
            case PositionStatus.first:
              return favorites.first.id == chatId;

            case PositionStatus.last:
              return favorites.last.id == chatId;
          }
        });
      },
    );

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

import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';

import '../configuration.dart';
import '../parameters/muted_status.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Indicates whether a dialog [Chat]-dialog with the provided name is displayed
/// with the specified [MutedStatus] or not.
///
/// Examples:
/// - Then I see dialog with Bob as muted
/// - Then I see dialog with Bob as unmuted
final StepDefinitionGeneric seeDialogAsMuted =
    then2<TestUser, MutedStatus, CustomWorld>(
      'I see dialog with {user} as {muted}',
      (user, status, context) async {
        await context.world.appDriver.waitUntil(() async {
          await context.world.appDriver.waitForAppToSettle();

          final ChatId chatId = context.world.sessions[user.name]!.dialog!;

          switch (status) {
            case MutedStatus.muted:
              return context.world.appDriver.isPresent(
                context.world.appDriver.findByKeySkipOffstage(
                  'MuteIndicator_$chatId',
                ),
              );

            case MutedStatus.unmuted:
              return context.world.appDriver.isAbsent(
                context.world.appDriver.findByKeySkipOffstage(
                  'MuteIndicator_$chatId',
                ),
              );
          }
        });
      },
    );

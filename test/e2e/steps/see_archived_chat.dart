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
import '../parameters/archived_status.dart';
import '../world/custom_world.dart';

/// Indicates whether a [Chat] with the provided name is displayed with the
/// specified [ArchivedStatus].
///
/// Examples:
/// - Then I see "Example" chat as archived
/// - Then I see "Example" group as unarchived
final StepDefinitionGeneric seeChatAsArchived =
    then2<String, ArchivedStatus, CustomWorld>(
      'I see {string} (?:chat|group) as {archived}',
      (name, status, context) async {
        await context.world.appDriver.waitUntil(() async {
          final ChatId chatId = context.world.groups[name]!;

          final bool inArchive = await context.world.appDriver.isPresent(
            context.world.appDriver.findByKeySkipOffstage('ArchivedChats'),
          );

          switch (status) {
            case ArchivedStatus.archived:
              final isPresent =
                  inArchive &&
                  await context.world.appDriver.isPresent(
                    context.world.appDriver.findByKeySkipOffstage('$chatId'),
                  );

              return isPresent;

            case ArchivedStatus.unarchived:
              final isPresent =
                  !inArchive &&
                  await context.world.appDriver.isPresent(
                    context.world.appDriver.findByKeySkipOffstage('$chatId'),
                  );

              return isPresent;
          }
        }, timeout: const Duration(seconds: 30));
      },
    );

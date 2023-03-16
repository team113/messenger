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

import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';

import '../configuration.dart';
import '../parameters/selection_status.dart';
import '../world/custom_world.dart';

/// Indicates whether a [Chat] with the provided name is selected.
///
/// Examples:
/// - Then I see "Dummy" chat as selected
/// - Then I see "Dummy" chat as unselected
final StepDefinitionGeneric seeChatSelection =
    then2<String, SelectionStatus, CustomWorld>(
  'I see {string} chat as {selection}',
  (name, status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final ChatId chatId = context.world.groups[name]!;
        final Finder chat =
            context.world.appDriver.findByKeySkipOffstage('RecentChat_$chatId');

        return await context.world.appDriver.isPresent(
          context.world.appDriver.findByDescendant(
            chat,
            context.world.appDriver.findByKeySkipOffstage(
              status == SelectionStatus.selected ? 'Selected' : 'Unselected',
            ),
          ),
        );
      },
    );
  },
);

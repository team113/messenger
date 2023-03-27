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

import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';

import '../configuration.dart';
import '../parameters/iterable_amount.dart';
import '../world/custom_world.dart';

/// Indicates whether there are the provided amount of [ChatItem]s in the opened
/// [Chat].
///
/// Examples:
/// - Then I see some messages in chat
/// - Then I see no messages in chat
final StepDefinitionGeneric seeChatMessages =
    then1<IterableAmount, CustomWorld>(
  'I see {iterable_amount} messages in chat',
  (status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        switch (status) {
          case IterableAmount.no:
            return await context.world.appDriver.isPresent(
              context.world.appDriver.findByKeySkipOffstage('NoMessages'),
            );

          case IterableAmount.some:
            return await context.world.appDriver.isAbsent(
              context.world.appDriver.findByKeySkipOffstage('NoMessages'),
            );
        }
      },
    );
  },
);

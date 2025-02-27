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
import '../world/custom_world.dart';

/// Indicates whether a [Chat] with the provided name is dismissed.
///
/// Examples:
/// - Then I see "Example" chat as dismissed
final StepDefinitionGeneric seeChatAsDismissed = then1<String, CustomWorld>(
  'I see {string} chat as dismissed',
  (name, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final ChatId chatId = context.world.groups[name]!;

      return await context.world.appDriver.isPresent(
        context.world.appDriver.findByKeySkipOffstage('Dismissed_$chatId'),
      );
    });
  },
);

/// Indicates whether no [Chat]s are displayed as dismissed.
///
/// Examples:
/// - Then I see no chats dismissed
final StepDefinitionGeneric seeNoChatsDismissed = then<
  CustomWorld
>('I see no chats dismissed', (context) async {
  print('=== seeNoChatsDismissed -> begin');

  await context.world.appDriver.waitUntil(() async {
    print('=== seeNoChatsDismissed -> waitForAppToSettle()...');
    await context.world.appDriver.waitForAppToSettle();
    print('=== seeNoChatsDismissed -> waitForAppToSettle()... done');

    print(
      '=== seeNoChatsDismissed -> find(`NoDismissed`): ${context.world.appDriver.findByKeySkipOffstage('NoDismissed')}',
    );

    final isPresent = await context.world.appDriver.isPresent(
      context.world.appDriver.findByKeySkipOffstage('NoDismissed'),
    );

    print('=== seeNoChatsDismissed -> isPresent: $isPresent');

    return isPresent;
  });

  print('=== seeNoChatsDismissed -> end');
});

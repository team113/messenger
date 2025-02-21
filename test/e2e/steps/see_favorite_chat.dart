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
import '../parameters/favorite_status.dart';
import '../world/custom_world.dart';

/// Indicates whether a [Chat] with the provided name is displayed with the
/// specified [FavoriteStatus].
///
/// Examples:
/// - Then I see "Example" chat as favorite
/// - Then I see "Example" chat as unfavorite
final StepDefinitionGeneric seeChatAsFavorite = then2<
  String,
  FavoriteStatus,
  CustomWorld
>('I see {string} chat as {favorite}', (name, status, context) async {
  print('===== seeChatAsFavorite($name, ${status.name}) -> started');

  await context.world.appDriver.waitUntil(() async {
    print(
      '===== seeChatAsFavorite($name, ${status.name}) -> waitForAppToSettle()...',
    );
    // await context.world.appDriver.waitForAppToSettle();
    await Future.delayed(Duration(seconds: 10));
    print(
      '===== seeChatAsFavorite($name, ${status.name}) -> waitForAppToSettle()... done',
    );

    final ChatId chatId = context.world.groups[name]!;

    switch (status) {
      case FavoriteStatus.favorite:
        print(
          '===== seeChatAsFavorite($name, ${status.name}) -> isPresent(FavoriteIndicator_$chatId)... finder: ${context.world.appDriver.findByKeySkipOffstage('FavoriteIndicator_$chatId')}',
        );

        final isPresent = await context.world.appDriver.isPresent(
          context.world.appDriver.findByKeySkipOffstage(
            'FavoriteIndicator_$chatId',
          ),
        );

        print(
          '===== seeChatAsFavorite($name, ${status.name}) -> isPresent -> $isPresent',
        );

        return isPresent;

      case FavoriteStatus.unfavorite:
        print(
          '===== seeChatAsFavorite($name, ${status.name}) -> isPresent(FavoriteIndicator_$chatId)... finder: ${context.world.appDriver.findByKeySkipOffstage('FavoriteIndicator_$chatId')}',
        );

        final isPresent = await context.world.appDriver.isAbsent(
          context.world.appDriver.findByKeySkipOffstage(
            'FavoriteIndicator_$chatId',
          ),
        );

        print(
          '===== seeChatAsFavorite($name, ${status.name}) -> isPresent -> $isPresent',
        );

        return isPresent;
    }
  }, timeout: const Duration(seconds: 30));

  print('===== seeChatAsFavorite($name, ${status.name}) -> done');
});

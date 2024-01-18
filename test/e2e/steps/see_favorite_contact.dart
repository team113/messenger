// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/domain/model/contact.dart';

import '../configuration.dart';
import '../parameters/favorite_status.dart';
import '../world/custom_world.dart';

/// Indicates whether a [ChatContact] with the provided name is displayed with
/// the specified [FavoriteStatus].
///
/// Examples:
/// - Then I see "Bob" contact as favorite
final StepDefinitionGeneric seeContactAsFavorite =
    then2<String, FavoriteStatus, CustomWorld>(
  'I see {string} contact as {favorite}',
  (name, status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final ChatContactId contactId = context.world.contacts[name]!;

        switch (status) {
          case FavoriteStatus.favorite:
            return await context.world.appDriver.isPresent(
              context.world.appDriver
                  .findByKeySkipOffstage('FavoriteIndicator_$contactId'),
            );

          case FavoriteStatus.unfavorite:
            return await context.world.appDriver.isAbsent(
              context.world.appDriver
                  .findByKeySkipOffstage('FavoriteIndicator_$contactId'),
            );
        }
      },
    );
  },
);

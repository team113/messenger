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

import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/contact.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Indicates whether a [ChatContact] with the provided name is dismissed.
///
/// Examples:
/// - Then I see "Example" contact as dismissed
final StepDefinitionGeneric seeContactAsDismissed = then1<String, CustomWorld>(
  'I see {string} contact as dismissed',
  (name, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final ChatContactId contactId = context.world.contacts[name]!;

      return await context.world.appDriver.isPresent(
        context.world.appDriver.findByKeySkipOffstage('Dismissed_$contactId'),
      );
    });
  },
);

/// Indicates whether no [ChatContact]s are displayed as dismissed.
///
/// Examples:
/// - Then I see no chats dismissed
final StepDefinitionGeneric seeNoContactsDismissed = then<CustomWorld>(
  'I see no contacts dismissed',
  (context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();
      return await context.world.appDriver.isPresent(
        context.world.appDriver.findByKeySkipOffstage('NoDismissed'),
      );
    });
  },
);

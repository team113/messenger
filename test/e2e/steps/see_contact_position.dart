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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/ui/page/home/tab/contacts/controller.dart';

import '../parameters/position_status.dart';
import '../world/custom_world.dart';

/// Indicates whether a [ChatContact] with the provided name is displayed at the
/// specified [PositionStatus].
///
/// Examples:
/// - Then I see "Bob" contact first in contacts list
/// - Then I see "Bob" contact last in contacts list
final StepDefinitionGeneric seeContactPosition =
    then2<String, PositionStatus, CustomWorld>(
  'I see {string} contact {position} in contacts list',
  (name, status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final controller = Get.find<ContactsTabController>();
        final ChatContactId contactId = context.world.contacts[name]!;

        switch (status) {
          case PositionStatus.first:
            return controller.favorites.first.id == contactId;

          case PositionStatus.last:
            return controller.favorites.indexWhere((e) => e.id == contactId) ==
                -1;
        }
      },
    );
  },
);

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

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:flutter/material.dart';
import 'package:messenger/domain/model/contact.dart';

import '../world/custom_world.dart';

/// Drags contact with specified name to specified amount pixels to down.
///
/// Examples:
/// - When I drag "Name" contact to 200 pixels down
final StepDefinitionGeneric dragContactToDown =
    given2<String, int, CustomWorld>(
  'I drag {string} contact to {int} pixels down',
  (String name, int offset, context) async {
    final ChatContactId contactId = context.world.contacts[name]!;
    await context.world.appDriver.waitUntil(() async {
      var finder = context.world.appDriver.findBy(
        Key('ContactReorder_${contactId.val}'),
        FindType.key,
      );
      if (await context.world.appDriver.isAbsent(finder)) return false;

      await context.world.appDriver.nativeDriver.drag(
        finder,
        Offset(0, offset.toDouble()),
      );
      return true;
    });
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

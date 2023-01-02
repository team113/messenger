// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '../world/custom_world.dart';

/// Long presses a [ChatContact] with the provided name.
///
/// Examples:
/// - When I long press "Bob" contact
final StepDefinitionGeneric longPressContact = when1<String, CustomWorld>(
  'I long press {string} contact',
  (name, context) async {
    await context.world.appDriver.waitForAppToSettle();
    final finder = context.world.appDriver.findBy(
      'Contact_${context.world.contacts[name]}',
      FindType.key,
    );

    await context.world.appDriver.nativeDriver.longPress(finder);
    await context.world.appDriver.waitForAppToSettle();
  },
);

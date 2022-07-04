// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

/// Taps the chat found with given name inside `ForwardModal`.
///
/// Examples:
/// - I tap chat named "Bob" inside modal
/// - I tap chat named "Charlie" inside modal
final StepDefinitionGeneric tapChatInsideModal = when1<String, CustomWorld>(
  'I tap chat named {string} inside modal',
  (name, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final finder = context.world.appDriver.findByDescendant(
        context.world.appDriver.findBy('ForwardModal', FindType.key),
        context.world.appDriver.findBy(name, FindType.text),
        firstMatchOnly: true,
      );
      if (await context.world.appDriver.isPresent(finder)) {
        await context.world.appDriver.tap(finder);
        return true;
      } else {
        return false;
      }
    }, timeout: const Duration(seconds: 30));
  },
);

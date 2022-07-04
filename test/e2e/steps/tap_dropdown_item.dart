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
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';

import '../parameters/keys.dart';

/// Taps dropdown with provided [dropdownKey] and then item with [menuItemKey].
final tapDropdownItem = given2<WidgetKey, WidgetKey, FlutterWorld>(
    RegExp(r'I tap (?:a|an|the) {key} within (?:a|an|the) {key} dropdown'),
    (menuItemKey, dropdownKey, context) async {
  await context.world.appDriver.waitForAppToSettle();
  final finder = context.world.appDriver.findBy(dropdownKey.name, FindType.key);

  await context.world.appDriver.scrollIntoView(
    finder,
  );
  await context.world.appDriver.waitForAppToSettle();
  await context.world.appDriver.tap(
    finder,
    timeout: context.configuration.timeout,
  );
  await context.world.appDriver.waitForAppToSettle();

  {
    final timeout =
        context.configuration.timeout ?? const Duration(seconds: 20);

    final finder = (context.world.appDriver
            .findBy(menuItemKey.name, FindType.key) as Finder)
        .last;

    final isPresent = await context.world.appDriver.isPresent(
      finder,
      timeout: timeout * .2,
    );

    if (!isPresent) {
      await context.world.appDriver.scrollUntilVisible(
        (context.world.appDriver.findBy(menuItemKey.name, FindType.key)
                as Finder)
            .last,
        dy: -100.0,
        timeout: timeout * .9,
      );
    }

    await context.world.appDriver.tap(
      finder,
      timeout: timeout,
    );
    await context.world.appDriver.waitForAppToSettle();
  }
});

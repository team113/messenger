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

/// Taps the provided [WidgetKey] item within the specified by its [WidgetKey]
/// dropdown.
final tapDropdownItem = given2<WidgetKey, WidgetKey, FlutterWorld>(
    RegExp(r'I tap {key} within {key} dropdown'),
    (item, dropdown, context) async {
  await context.world.appDriver.waitForAppToSettle();
  var finder = context.world.appDriver.findBy(dropdown.name, FindType.key);

  await context.world.appDriver.scrollIntoView(finder);
  await context.world.appDriver.waitForAppToSettle();
  await context.world.appDriver
      .tap(finder, timeout: context.configuration.timeout);
  await context.world.appDriver.waitForAppToSettle();

  finder =
      (context.world.appDriver.findBy(item.name, FindType.key) as Finder).last;
  final timeout = context.configuration.timeout ?? const Duration(seconds: 20);
  final isPresent =
      await context.world.appDriver.isPresent(finder, timeout: timeout * .2);

  if (!isPresent) {
    await context.world.appDriver.scrollUntilVisible(
      (context.world.appDriver.findBy(item.name, FindType.key) as Finder).last,
      dy: -100.0,
      timeout: timeout * .9,
    );
  }

  await context.world.appDriver.tap(finder, timeout: timeout);
  await context.world.appDriver.waitForAppToSettle();
});

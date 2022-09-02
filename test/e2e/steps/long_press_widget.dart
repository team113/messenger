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

import 'package:gherkin/gherkin.dart';

import '../configuration.dart';
import '../parameters/keys.dart';
import '../world/custom_world.dart';

/// Long presses the [Widget] found with the given [WidgetKey].
///
/// Examples:
/// - When I long press `WidgetKey` button
/// - When I long press `WidgetKey` element
/// - When I long press `WidgetKey` label
/// - When I long press `WidgetKey` icon
/// - When I long press `WidgetKey` field
/// - When I long press `WidgetKey` text
/// - When I long press `WidgetKey` widget
final StepDefinitionGeneric longPressWidget = when1<WidgetKey, CustomWorld>(
    RegExp(
        r'I long press {key} (?:button|element|label|icon|field|text|widget)$'),
    (key, context) async {
  await context.world.appDriver.waitForAppToSettle();
  final finder = context.world.appDriver.findByKeySkipOffstage(key.name);

  await context.world.appDriver.nativeDriver.longPress(finder);
  await context.world.appDriver.waitForAppToSettle();
});

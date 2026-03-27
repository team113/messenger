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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/repository/settings.dart';

import '../parameters/enabled_status.dart';
import '../world/custom_world.dart';

/// Enables or disables [ApplicationSettings.enablePopups].
///
/// Examples:
/// - Given popup windows are enabled
/// - Given popup windows are disabled
final StepDefinitionGeneric popupWindows = given1<EnabledStatus, CustomWorld>(
  'popup windows are {enabled}',
  (enabled, context) async {
    await context.world.appDriver.waitUntil(() async {
      try {
        await Get.find<AbstractSettingsRepository>().setPopupsEnabled(
          enabled == EnabledStatus.enabled,
        );
        return true;
      } catch (_) {
        return false;
      }
    });
  },
);

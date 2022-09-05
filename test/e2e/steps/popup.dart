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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/repository/settings.dart';

import '../parameters/enabled.dart';
import '../world/custom_world.dart';

/// Enables or disables opening calls in popup.
///
/// Examples:
/// - Given popup windows is enabled
/// - Given popup windows is disabled
final StepDefinitionGeneric popupWindows = given1<Enabled, CustomWorld>(
  'popup windows is {enabled}',
  (enabled, context) async {
    await context.world.appDriver.waitUntil(() async {
      try {
        if (enabled == Enabled.enabled) {
          await Get.find<AbstractSettingsRepository>().setPopupsEnabled(true);
        } else {
          await Get.find<AbstractSettingsRepository>().setPopupsEnabled(false);
        }
        return true;
      } catch (_) {
        return false;
      }
    });
  },
);

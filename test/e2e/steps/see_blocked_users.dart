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
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/ui/page/home/page/my_profile/blocklist/controller.dart';

import '../world/custom_world.dart';

/// Indicates whether the provided count of blocked [User]s are present within
/// [BlocklistView].
///
/// Examples:
/// - Then I see 30 blocked users
final StepDefinitionGeneric seeBlockedUsers = then1<int, CustomWorld>(
  'I see {int} blocked users',
  (count, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle(timeout: 1.seconds);

      final controller = Get.find<BlocklistController>();
      if (controller.blocklist.length == count) {
        return true;
      } else {
        return false;
      }
    }, timeout: const Duration(seconds: 30));
  },
);

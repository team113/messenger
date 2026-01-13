// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/util/get.dart';

import '../world/custom_world.dart';

/// Creates a new [MyUser] as a guest.
///
/// Examples:
/// - Given I am guest
final StepDefinitionGeneric iAmGuest = given<CustomWorld>(
  'I am guest\$',
  (context) async {
    final AuthService authService = Get.find<AuthService>();
    await authService.register();

    // Ensure business logic is initialized.
    await context.world.appDriver.waitUntil(() async {
      return Get.findOrNull<MyUserService>()?.myUser.value != null;
    }, timeout: const Duration(seconds: 30));
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 30),
);

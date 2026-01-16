// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
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
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/util/get.dart';
import 'package:messenger/util/log.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Ensures the currently active [MyUser]'s name is the provided [TestUser].
///
/// Examples:
/// - Then my name is indeed Alice
final StepDefinitionGeneric
myNameIs = given1<TestUser, CustomWorld>('my name is indeed {user}', (
  TestUser user,
  context,
) async {
  await context.world.appDriver.waitUntil(() async {
    final MyUserService? myUserService = Get.findOrNull<MyUserService>();
    final bool equals = myUserService?.myUser.value?.name?.val == user.name;

    Log.debug(
      'myNameIs -> `${myUserService?.myUser.value?.name?.val}` == `${user.name}` -> ${myUserService?.myUser.value?.name?.val == user.name}',
      'E2E',
    );

    if (!equals) {
      Log.debug(
        'myNameIs -> ok, so the name isn\'t `${user.name}`. Here\'s the full JSON: ${myUserService?.myUser.value?.toJson()}',
        'E2E',
      );
    }

    return equals;
  });
});

/// Ensures the currently active [MyUser]'s name is not the provided [TestUser].
///
/// Examples:
/// - Then my name is not Alice
final StepDefinitionGeneric myNameIsNot = given1<TestUser, CustomWorld>(
  'my name is not {user}',
  (TestUser user, context) async {
    await context.world.appDriver.waitUntil(() async {
      return Get.find<MyUserService>().myUser.value?.name?.val != user.name;
    });
  },
);

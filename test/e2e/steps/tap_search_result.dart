// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/ui/page/call/search/controller.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Taps on the provided [User] or [ChatContact] found in an ongoing search.
///
/// Examples:
/// - Then I tap user Bob in search results
/// - Then I tap contact Charlie in search results
final StepDefinitionGeneric tapUserInSearchResults =
    then2<SearchCategory, TestUser, CustomWorld>(
  'I tap {search_category} {user} in search results',
  (SearchCategory category, TestUser user, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        switch (category) {
          case SearchCategory.contact:
            final ContactService contactService = Get.find<ContactService>();
            final ChatContactId id = contactService.contacts.values
                .firstWhere((e) => e.contact.value.name.val == user.name)
                .id;

            final finder = context.world.appDriver
                .findByKeySkipOffstage('SearchContact_$id');

            if (await context.world.appDriver.isPresent(finder)) {
              await context.world.appDriver.scrollIntoView(finder);
              await context.world.appDriver.tap(
                finder,
                timeout: context.configuration.timeout,
              );
              await context.world.appDriver.waitForAppToSettle();
              return true;
            }

            return false;

          case SearchCategory.user:
            final UserId userId = context.world.sessions[user.name]!.userId;

            final finder = context.world.appDriver
                .findByKeySkipOffstage('SearchUser_$userId');

            if (await context.world.appDriver.isPresent(finder)) {
              await context.world.appDriver.scrollIntoView(finder);
              await context.world.appDriver.tap(
                finder,
                timeout: context.configuration.timeout,
              );
              await context.world.appDriver.waitForAppToSettle();
              return true;
            }

            return false;

          case SearchCategory.recent:
          case SearchCategory.chat:
            throw Exception('Chat or recent cannot be a TestUser.');
        }
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

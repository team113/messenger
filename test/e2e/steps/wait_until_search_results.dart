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
import 'package:flutter_gherkin/src/flutter/parameters/existence_parameter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/contact.dart';

import '../parameters/search_chats.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Waits until the provided [User] in chats searching is present or absent.
///
/// Examples:
/// - Then I wait until Bob user in search results is absent
/// - Then I wait until Bob user in search results is present
final StepDefinitionGeneric untilUserInSearchResults =
    then2<TestUser, Existence, CustomWorld>(
  'I wait until {user} user in search results is {existence}',
  (TestUser user, Existence existence, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final UserId userId = context.world.sessions[user.name]!.userId;

        Finder finder = context.world.appDriver.findBy(
          'SearchUser_$userId',
          FindType.key,
        );

        return existence == Existence.absent
            ? context.world.appDriver.isAbsent(finder)
            : context.world.appDriver.isPresent(finder);
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

/// Waits until the provided [Contact] or [Chat] in chats searching is present
/// or absent.
///
/// Examples:
/// - Then I wait until "Example" chat in search results is absent
/// - Then I wait until "Example" chat in search results is present
/// - Then I wait until "Charlie" contact in search results is present
/// - Then I wait until "Charlie" contact in search results is present
final StepDefinitionGeneric untilContactOrChatInSearchResults =
    then3<String, WhatToSearchInChats, Existence, CustomWorld>(
  'I wait until {string} {search_in_chats} in search results is {existence}',
  (String name, WhatToSearchInChats search, Existence existence,
      context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        String searchKey = '';

        if (search == WhatToSearchInChats.chat) {
          final ChatId chatId = context.world.groups[name]!;

          searchKey = 'SearchChat_$chatId';
        } else if (search == WhatToSearchInChats.contact) {
          ContactService contactService = Get.find<ContactService>();

          final ChatContactId contactId = contactService.contacts.values
              .firstWhere((e) => e.contact.value.name.val == name)
              .id;

          searchKey = 'SearchContact_$contactId';
        }

        Finder finder = context.world.appDriver.findBy(
          searchKey,
          FindType.key,
        );

        return existence == Existence.absent
            ? context.world.appDriver.isAbsent(finder)
            : context.world.appDriver.isPresent(finder);
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

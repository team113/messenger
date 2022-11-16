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

import '../parameters/seach_chats.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Waits until the provided text is present or absent.
///
/// Examples:
/// - Then I wait until text "Dummy" is absent
/// - Then I wait until text "Dummy" is present
final StepDefinitionGeneric untilUserInSearchResults =
    then2<TestUser, Existence, CustomWorld>(
  'I wait until {user} user in search results is {existence}',
  (TestUser user, Existence existence, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final UserId userId = context.world.sessions[user.name]!.userId;

        return existence == Existence.absent
            ? context.world.appDriver.isAbsent(
                context.world.appDriver
                    .findBy('SearchUser_$userId', FindType.key),
              )
            : context.world.appDriver.isPresent(
                context.world.appDriver
                    .findBy('SearchUser_$userId', FindType.key),
              );
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

/// Waits until the provided text is present or absent.
///
/// Examples:
/// - Then I wait until text "Dummy" is absent
/// - Then I wait until text "Dummy" is present
final StepDefinitionGeneric untilChatInSearchResults =
    then3<String, SearchChats, Existence, CustomWorld>(
  'I wait until {string} {search_chats} in search results is {existence}',
  (String name, SearchChats search, Existence existence, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        String searchKey = '';

        if (search == SearchChats.chat) {
          final ChatId chatId = context.world.groups[name]!;

          searchKey = 'SearchChat_$chatId';
        } else if (search == SearchChats.contact) {
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

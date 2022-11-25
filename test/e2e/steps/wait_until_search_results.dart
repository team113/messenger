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
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/contact.dart';

import '../parameters/search_chats.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Waits until the provided [User] or [Contact] in chats searching is
/// displayed.
///
/// Examples:
/// - Then I see user Bob in search results
/// - Then I see contact Charlie in search results
final StepDefinitionGeneric seeUserOrContactInSearchResults =
    then2<SearchCategory, TestUser, CustomWorld>(
  'I see {search_in_chats} {user} in search results',
  (SearchCategory search, TestUser user, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        String searchKey = '';

        if (search == SearchCategory.user) {
          final UserId userId = context.world.sessions[user.name]!.userId;

          searchKey = 'SearchUser_$userId';
        } else if (search == SearchCategory.contact) {
          ContactService contactService = Get.find<ContactService>();

          final ChatContactId contactId = contactService.contacts.values
              .firstWhere((e) => e.contact.value.name.val == user.name)
              .id;

          searchKey = 'SearchContact_$contactId';
        }

        return context.world.appDriver.isPresent(
          context.world.appDriver.findBy(
            searchKey,
            FindType.key,
          ),
        );
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

/// Waits until the provided [Chat] in chats searching is displayed.
///
/// Examples:
/// - Then I see chat "Example" in search results
final StepDefinitionGeneric seeChatInSearchResults = then1<String, CustomWorld>(
  'I see chat {string} in search results',
  (String name, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final ChatId chatId = context.world.groups[name]!;

        return context.world.appDriver.isPresent(
          context.world.appDriver.findBy(
            'SearchChat_$chatId',
            FindType.key,
          ),
        );
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

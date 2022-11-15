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

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Waits until the provided text is present or absent.
///
/// Examples:
/// - Then I wait until text "Dummy" is absent
/// - Then I wait until text "Dummy" is present
final StepDefinitionGeneric untilChatInSearchResults =
    then1<String, CustomWorld>(
  'I wait until {string} chat in search results',
  (String name, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final ChatId chatId = context.world.groups[name]!;

        return context.world.appDriver.isPresent(
          context.world.appDriver.findBy('SearchChat_$chatId', FindType.key),
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
final StepDefinitionGeneric untilUserInSearchResults =
    then1<TestUser, CustomWorld>(
  'I wait until {user} user in search results',
  (TestUser user, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final UserId userId = context.world.sessions[user.name]!.userId;

        return context.world.appDriver.isPresent(
          context.world.appDriver.findBy('SearchUser_$userId', FindType.key),
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
final StepDefinitionGeneric untilContactInSearchResults =
    then1<String, CustomWorld>(
  'I wait until {string} contact in search results',
  (String contact, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        ContactService contactService = Get.find<ContactService>();

        final ChatContactId contactId = contactService.contacts.values
            .firstWhere((e) => e.contact.value.name.val == contact)
            .id;

        return context.world.appDriver.isPresent(
          context.world.appDriver
              .findBy('SearchContact_$contactId', FindType.key),
        );
      },
      timeout: const Duration(seconds: 30),
    );
  },
);

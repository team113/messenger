// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/widgets.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/ui/page/call/search/controller.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';
import 'scroll_until.dart';

/// Waits until the provided [User] or [ChatContact] is found and displayed in
/// the ongoing search results.
///
/// Examples:
/// - Then I see user Bob in search results
/// - Then I see contact Charlie in search results
final StepDefinitionGeneric
seeUserInSearchResults = then2<SearchCategory, TestUser, CustomWorld>(
  'I see {search_category} {user} in search results',
  (SearchCategory category, TestUser user, context) async {
    await context.world.appDriver.waitUntil(() async {
      switch (category) {
        case SearchCategory.contact:
          final ContactService contactService = Get.find<ContactService>();
          final ChatContactId id = contactService.paginated.values
              .firstWhere((e) => e.contact.value.name.val == user.name)
              .id;
          return context.world.appDriver.isPresent(
            context.world.appDriver.findBy('SearchContact_$id', FindType.key),
          );

        case SearchCategory.user:
          final UserId userId = context.world.sessions[user.name]!.userId;

          final scrollable = find.descendant(
            of: find.byKey(const Key('SearchScrollable')),
            matching: find.byWidgetPredicate((widget) {
              // TODO: Find a proper way to differentiate [Scrollable]s from
              //       [TextField]s:
              //       https://github.com/flutter/flutter/issues/76981
              if (widget is Scrollable) {
                return widget.restorationId == null;
              }
              return false;
            }),
          );

          if (!await context.world.appDriver.isPresent(scrollable)) {
            return false;
          }

          final Finder searchUser = context.world.appDriver
              .findByKeySkipOffstage('SearchUser_$userId');

          final Finder searchChat = context.world.appDriver
              .findByKeySkipOffstage(
                'SearchChat_${context.world.sessions[user.name]?.dialog}',
              );

          final Finder searchDialog = context.world.appDriver
              .findByKeySkipOffstage('SearchChat_$userId');

          bool hasUser = await context.world.appDriver.isPresent(searchUser);
          bool hasChat = await context.world.appDriver.isPresent(searchChat);
          bool hasDialog = await context.world.appDriver.isPresent(
            searchDialog,
          );

          if (!hasUser && !hasChat && !hasDialog) {
            await context.world.appDriver.scrollIntoVisible(
              searchUser,
              scrollable,
              dy: 100,
            );

            hasUser = await context.world.appDriver.isPresent(searchUser);

            if (!hasUser) {
              await context.world.appDriver.scrollIntoVisible(
                searchChat,
                scrollable,
                dy: 100,
              );

              hasChat = await context.world.appDriver.isPresent(searchChat);

              if (!hasChat) {
                await context.world.appDriver.scrollIntoVisible(
                  searchDialog,
                  scrollable,
                  dy: 100,
                );

                hasDialog = await context.world.appDriver.isPresent(
                  searchDialog,
                );
              }
            }
          }

          return hasUser || hasChat || hasDialog;

        case SearchCategory.recent:
        case SearchCategory.chat:
          throw Exception('Chat or recent cannot be a TestUser.');
      }
    }, timeout: const Duration(seconds: 30));
  },
);

/// Waits until a group [Chat] with the provided [name] is found and displayed
/// in the ongoing search results.
///
/// Examples:
/// - Then I see chat "Example" in search results
/// - Then I see recent "Example" in search results
final StepDefinitionGeneric seeChatInSearchResults = then1<String, CustomWorld>(
  'I see chat {string} in search results',
  (String name, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final ChatId chatId = context.world.groups[name]!;
      return context.world.appDriver.isPresent(
        context.world.appDriver.findBy('SearchChat_$chatId', FindType.key),
      );
    }, timeout: const Duration(seconds: 30));
  },
);

/// Waits until a [Chat]-dialog with provided [User] is found and displayed in
/// the ongoing search results.
///
/// Examples:
/// - Then I see chat with Bob in search results
final StepDefinitionGeneric seeChatWithUserInSearchResults =
    then1<TestUser, CustomWorld>('I see chat with {user} in search results', (
      TestUser user,
      context,
    ) async {
      await context.world.appDriver.waitUntil(() async {
        await context.world.appDriver.waitForAppToSettle();

        final ChatId? chatId = context.world.sessions[user.name]?.dialog;
        if (chatId != null) {
          return context.world.appDriver.isPresent(
            context.world.appDriver.findBy('SearchChat_$chatId', FindType.key),
          );
        }

        return false;
      }, timeout: const Duration(seconds: 30));
    });

/// Waits until the monolog is found and displayed in the ongoing search
/// results.
final StepDefinitionGeneric seeMonologInSearchResults = then<CustomWorld>(
  'I see monolog in search results',
  (context) async {
    await context.world.appDriver.waitUntil(() async {
      final ChatService chatService = Get.find<ChatService>();
      final ChatId chatId = chatService.monolog;
      final ChatId monologId = ChatId.local(chatService.me!);

      final bool isPresent = await context.world.appDriver.isPresent(
        context.world.appDriver.findBy('SearchChat_$chatId', FindType.key),
      );

      if (!isPresent) {
        return await context.world.appDriver.isPresent(
          context.world.appDriver.findBy('SearchChat_$monologId', FindType.key),
        );
      }

      return isPresent;
    }, timeout: const Duration(seconds: 30));
  },
);

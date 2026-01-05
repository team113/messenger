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
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Creates a [Chat]-group with the the authenticated [MyUser].
///
/// Examples:
/// - Given I have "Name" group.
final StepDefinitionGeneric haveGroupNamed = given1<String, CustomWorld>(
  'I have {string} group',
  (String name, context) async {
    final ChatService chatService = Get.find();
    final chat = await chatService.createGroupChat([], name: ChatName(name));
    context.world.groups[name] = chat.id;
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates a [Chat]-group with the the provided [TestUser].
///
/// Examples:
/// - Given Alice has "Name" group.
final StepDefinitionGeneric hasGroupNamed =
    given2<TestUser, String, CustomWorld>(
      '{user} has {string} group\$',
      (TestUser user, String name, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        final ChatMixin chat = await provider.createGroupChat(
          [],
          name: ChatName(name),
        );

        context.world.groups[name] = chat.id;

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Creates a [Chat]-group with the the provided [TestUser].
///
/// Examples:
/// - Given Alice has "Name" group.
final StepDefinitionGeneric hasGroupNamedInArchive =
    given2<TestUser, String, CustomWorld>(
      '{user} has {string} group in archive\$',
      (TestUser user, String name, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        final ChatMixin chat = await provider.createGroupChat(
          [],
          name: ChatName(name),
        );

        await provider.toggleChatArchivation(chat.id, true);

        context.world.groups[name] = chat.id;

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Creates a [Chat]-group with the provided [User] and the authenticated
/// [MyUser].
///
/// Examples:
/// - Given I have "Name" group with Bob.
final StepDefinitionGeneric haveGroup1Named =
    given2<String, TestUser, CustomWorld>(
      'I have {string} group with {user}\$',
      (String name, TestUser user, context) async {
        final ChatService chatService = Get.find();

        final chat = await chatService.createGroupChat([
          context.world.sessions[user.name]!.userId,
        ], name: ChatName(name));

        context.world.groups[name] = chat.id;
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Creates a [Chat]-group with the provided [User]s and the authenticated
/// [MyUser].
///
/// Examples:
/// - Given I have "Name" group with Bob and Charlie.
final StepDefinitionGeneric haveGroup2Named =
    given3<String, TestUser, TestUser, CustomWorld>(
      'I have {string} group with {user} and {user}\$',
      (String name, TestUser bob, TestUser charlie, context) async {
        final ChatService chatService = Get.find();

        final chat = await chatService.createGroupChat([
          context.world.sessions[bob.name]!.userId,
          context.world.sessions[charlie.name]!.userId,
        ], name: ChatName(name));

        context.world.groups[name] = chat.id;
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Creates a [Chat]-group with the provided [User]s and the authenticated
/// [MyUser].
///
/// Examples:
/// - Given I have group with Bob and Charlie.
final StepDefinitionGeneric haveGroup2 =
    given2<TestUser, TestUser, CustomWorld>(
      'I have group with {user} and {user}\$',
      (TestUser bob, TestUser charlie, context) async {
        final ChatService chatService = Get.find();

        final chat = await chatService.createGroupChat([
          context.world.sessions[bob.name]!.userId,
          context.world.sessions[charlie.name]!.userId,
        ], name: null);

        context.world.groups[chat.title()] = chat.id;
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Creates the specified amount of [Chat]-groups for the provided [TestUser].
///
/// Examples:
/// - Given Alice has 5 groups.
final StepDefinitionGeneric hasGroups = given2<TestUser, int, CustomWorld>(
  '{user} has {int} groups',
  (TestUser user, int count, context) async {
    final GraphQlProvider provider = GraphQlProvider()
      ..client.withWebSocket = false
      ..token = context.world.sessions[user.name]?.token;

    for (int i = 0; i < count; i++) {
      await provider.createGroupChat([]);
    }

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates the specified amount of favorite [Chat]-groups for the provided
/// [TestUser].
///
/// Examples:
/// - Given Alice has 5 favorite groups.
final StepDefinitionGeneric hasFavoriteGroups =
    given2<TestUser, int, CustomWorld>(
      '{user} has {int} favorite groups',
      (TestUser user, int count, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        for (int i = 0; i < count; i++) {
          ChatMixin chat = await provider.createGroupChat([]);
          await provider.favoriteChat(
            chat.id,
            ChatFavoritePosition((i + 1).toDouble()),
          );
        }

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Creates a [Chat]-group with the the authenticated [MyUser] and provided
/// count of members.
///
/// Examples:
/// - Given Alice has "Name" group with 30 members.
final StepDefinitionGeneric hasGroupWithMembers =
    given3<TestUser, String, int, CustomWorld>(
      '{user} has {string} group with {int} members\$',
      (TestUser user, String name, int count, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        final List<CustomUser> users = await Future.wait(
          List.generate(count - 1, (_) => createUser()),
        );

        final chat = await provider.createGroupChat(
          users.map((e) => e.userId).toList(),
          name: ChatName(name),
        );

        context.world.groups[name] = chat.id;

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

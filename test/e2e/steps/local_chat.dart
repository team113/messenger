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

import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/recent_chat.dart';
import 'package:messenger/store/model/chat.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Creates a local [Chat] for the provided [User].
///
/// Examples:
/// - Given Alice has local chat.
final StepDefinitionGeneric hasLocalChat = given1<TestUser, CustomWorld>(
  '{user} has local chat',
  (TestUser user, context) async {
    ChatHiveProvider chatProvider = ChatHiveProvider();
    await chatProvider.init(userId: context.world.sessions[user.name]!.userId);
    await chatProvider.put(
      HiveChat(
        Chat(const ChatId('localChat'), name: ChatName('local')),
        ChatVersion('0'),
        null,
        null,
        null,
        null,
      ),
    );
    await chatProvider.close();

    RecentChatHiveProvider recentChatProvider = RecentChatHiveProvider();
    await recentChatProvider.init(
      userId: context.world.sessions[user.name]!.userId,
    );
    await recentChatProvider.put(
      const ChatId('localChat'),
      PreciseDateTime.now(),
    );
    await recentChatProvider.close();

    context.world.groups['local'] = const ChatId('localChat');
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

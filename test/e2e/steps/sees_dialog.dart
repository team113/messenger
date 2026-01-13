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
import 'package:messenger/api/backend/schema.dart' show ChatKind;
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/ui/page/home/tab/chats/controller.dart';
import 'package:messenger/util/log.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Ensures that the provided [User] has a dialog with the authenticated
/// [MyUser] in their recent [Chat]s.
///
/// Examples:
/// - Then Bob sees dialog with me in recent chats.
final StepDefinitionGeneric seesDialogWithMe = then1<TestUser, CustomWorld>(
  '{user} sees dialog with me in recent chats',
  (TestUser user, context) async {
    final GraphQlProvider provider = GraphQlProvider()
      ..client.withWebSocket = false;

    try {
      await context.world.appDriver.waitUntil(() async {
        provider.token = context.world.sessions[user.name]?.token;
        final dialog = (await provider.recentChats(first: 120))
            .recentChats
            .edges
            .firstWhereOrNull(
              (e) =>
                  e.node.kind == ChatKind.dialog &&
                  e.node.members.nodes.any(
                    (m) => m.user.id == context.world.me,
                  ),
            );
        return dialog != null;
      });
    } finally {
      provider.disconnect();
    }
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Ensures that the provided [User] has no dialog with the authenticated
/// [MyUser] in their recent [Chat]s.
///
/// Examples:
/// - Then Bob sees no dialog with me in recent chats.
final StepDefinitionGeneric seesNoDialogWithMe = then1<TestUser, CustomWorld>(
  '{user} sees no dialog with me in recent chats',
  (TestUser user, context) async {
    final GraphQlProvider provider = GraphQlProvider()
      ..client.withWebSocket = false
      ..token = context.world.sessions[user.name]?.token;

    final dialog = (await provider.recentChats(first: 120)).recentChats.edges
        .firstWhereOrNull(
          (e) =>
              e.node.kind == ChatKind.dialog &&
              e.node.members.nodes.any((m) => m.user.id == context.world.me),
        );

    provider.disconnect();

    assert(dialog == null, true);
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Indicates whether a dialog [Chat] with the provided name is not displayed
/// in the list of chats.
///
/// Examples:
/// - Then I see no dialog with Bob
final StepDefinitionGeneric seesNoDialogWithUser = then1<TestUser, CustomWorld>(
  'I see no dialog with {user}',
  (TestUser user, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.nativeDriver.pump(
        const Duration(seconds: 2),
      );

      final ChatsTabController controller = Get.find<ChatsTabController>();
      final ChatId chatId = context.world.sessions[user.name]!.dialog!;
      final ChatEntry? dialog = controller.chats.firstWhereOrNull(
        (c) => c.chat.value.id == chatId,
      );

      Log.debug(
        'seesNoDialogWithUser(${user.name}) -> chatId($chatId), dialog($dialog)',
        'E2E',
      );

      if (dialog == null) {
        Log.debug(
          'seesNoDialogWithUser(${user.name}) -> seems like `dialog` is `null`, thus the whole controller list: ${controller.chats.map((e) => e.chat.value)}',
          'E2E',
        );
      }

      return dialog?.chat.value.isHidden != false;
    }, timeout: const Duration(seconds: 30));
  },
);

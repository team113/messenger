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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/api/backend/schema.dart' show GetMessages$Query;
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/store/model/chat_item.dart';
import 'package:messenger/store/model/page_info.dart';
import 'package:messenger/store/pagination/graphql.dart';
import 'package:messenger/store/pagination/hive.dart';
import 'package:messenger/store/pagination/hive_graphql.dart';
import 'package:messenger/store/pagination.dart';
import 'package:messenger/config.dart';

String consoleList<U>(RxList<U> items) {
  return '${items.map((m) {
    if (m is HiveChatMessage) {
      return '${(m.value as ChatMessage).text}';
    }
    return '$m';
  })}';
}

void main() async {
  test('Parsing UserPhone successfully', () async {
    Hive.init('./test/.temp_hive/pagination3_unit');
    await Config.init();
    const ChatId chatId = ChatId('afac093a-ee9a-4036-9ccf-d9b00982cb4c');

    final ChatItemHiveProvider chatItemProvider = ChatItemHiveProvider(chatId);
    await chatItemProvider.init();
    await chatItemProvider.clear();

    print('In `ChatItem` Hive: ${chatItemProvider.keys.length} items');

    final GraphQlProvider graphQlProvider = GraphQlProvider();

    try {
      final response = await graphQlProvider.signIn(
        UserPassword('123'),
        UserLogin('nikita'),
        null,
        null,
        null,
        false,
      );
      graphQlProvider.token = response.session.token;
    } catch (e) {
      final response = await graphQlProvider.signUp();
      graphQlProvider.token = response.createUser.session.token;

      await graphQlProvider.updateUserLogin(UserLogin('nikita'));
      await graphQlProvider.updateUserPassword(null, UserPassword('123'));

      final signIn = await graphQlProvider.signIn(
        UserPassword('123'),
        UserLogin('nikita'),
        null,
        null,
        null,
        false,
      );
      graphQlProvider.token = signIn.session.token;
    }

    if (false) {
      final chat = await graphQlProvider.createGroupChat([]);
      print(chat.id.val);

      for (int i = 1; i <= 100; ++i) {
        await graphQlProvider.postChatMessage(
          chat.id,
          text: ChatMessageText('$i'),
        );
      }

      return true;
    }

    final Pagination<HiveChatItem, String, ChatItemsCursor> pagination =
        Pagination(
      perPage: 4,
      onKey: (i) => i.value.key,
      provider: HiveGraphQlPageProvider(
        HivePageProvider<HiveChatItem, ChatItemsCursor>(
          chatItemProvider,
          getKey: (i) => i.value.key,
          getCursor: (i) => i?.cursor,
        ),
        GraphQlPageProvider<HiveChatItem, ChatItemsCursor>(
          fetch: ({after, before, first, last}) async {
            final q = await graphQlProvider.chatItems(
              chatId,
              first: first,
              after: after,
              last: last,
              before: before,
            );

            final PageInfo<ChatItemsCursor> info =
                q.chat!.items.pageInfo.toModel((e) => ChatItemsCursor(e));
            return Page(
              RxList(q.chat!.items.edges.map((e) => e.toHive()).toList()),
              PageInfo<ChatItemsCursor>(
                hasNext: info.hasNext,
                hasPrevious: info.hasPrevious,
                startCursor: info.startCursor,
                endCursor: info.endCursor,
              ),
            );
          },
        ),
      ),
    );

    void console() {
      print('\n');
      print('${pagination.items.values.map((m) {
        if (m is HiveChatMessage) {
          return '${(m.value as ChatMessage).text}';
        }
        return '$m';
      })} (${pagination.startCursor} to ${pagination.endCursor})');
      print('\n');
    }

    await pagination.around();
    console();

    // await Future.delayed(const Duration(seconds: 2));
    // console();

    await pagination.previous();
    console();

    await pagination.next();
    console();

    // pagination.put(HiveChatMessage.sending(
    //   chatId: chatId,
    //   me: const UserId('me'),
    //   text: ChatMessageText('sending'),
    // ));
    // pagination.put(HiveChatMessage.sending(
    //   chatId: chatId,
    //   me: const UserId('me'),
    //   text: ChatMessageText('sending'),
    // ));

    console();

    print(
      'hasPrevious: ${pagination.hasPrevious}, hasNext: ${pagination.hasNext}',
    );
  });
}

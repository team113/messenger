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
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/store/model/chat_item.dart';
import 'package:messenger/store/model/page_info.dart';
import 'package:messenger/store/pagination/graphql.dart';
import 'package:messenger/store/pagination.dart';
import 'package:messenger/config.dart';

void main() async {
  test('Parsing UserPhone successfully', () async {
    await Config.init();
    const ChatId chatId = ChatId('99404e9a-e2e5-4b29-bd76-fff11dfc3796');

    final GraphQlProvider graphQlProvider = GraphQlProvider();
    final response = await graphQlProvider.signIn(
      UserPassword('123'),
      UserLogin('nikita'),
      null,
      null,
      null,
      false,
    );
    graphQlProvider.token = response.session.token;

    final Pagination<HiveChatItem, String, ChatItemsCursor> pagination =
        Pagination(
      perPage: 4,
      onKey: (i) => i.value.key.toString(),
      provider: GraphQlPageProvider<HiveChatItem, ChatItemsCursor>(
        fetch: ({after, before, first, last}) async {
          final q = await graphQlProvider.chatItems(
            chatId,
            first: first,
            after: after,
            last: last,
            before: before,
          );

          final PageInfo<ChatItemsCursor> info =
              q.chat!.items.pageInfo.toModel((c) => ChatItemsCursor(c));
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
    );

    void console() {
      print('${pagination.items.values.map((m) {
        if (m is HiveChatMessage) {
          return '${(m.value as ChatMessage).text}';
        }
        return '$m';
      })} (${pagination.startCursor} to ${pagination.endCursor})');
      // print(
      //   pagination.pages.map(
      //     (e) => '[${e.edges.map((m) {
      //       if (m is HiveChatMessage) {
      //         return '${(m.value as ChatMessage).text}';
      //       }
      //       return '$m';
      //     })}] (${e.info.startCursor} to ${e.info.endCursor})',
      //   ),
      // );
    }

    await pagination.around();
    console();

    await pagination.next();
    console();

    await pagination.previous();
    console();

    await pagination.next();
    console();

    print(
      'hasPrevious: ${pagination.hasPrevious.value}, hasNext: ${pagination.hasNext.value}',
    );
  });
}

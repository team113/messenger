// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:log_me/log_me.dart';
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/api/backend/extension/page_info.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/provider/drift/chat_item.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/store/model/chat_item.dart';
import 'package:messenger/store/model/page_info.dart';
import 'package:messenger/store/pagination.dart';
import 'package:messenger/store/pagination/drift.dart';
import 'package:messenger/store/pagination/drift_graphql.dart';
import 'package:messenger/store/pagination/graphql.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'pagination_test.mocks.dart';

class Key {
  const Key(this.i);
  final int i;
}

class Value {
  const Value(this.i);
  final int i;

  Key get key => Key(i);
  Cursor get cursor => Cursor(i);
}

class Cursor {
  const Cursor(this.i);
  final int i;
}

@GenerateMocks([GraphQlProvider])
void main() async {
  Log.options = const LogOptions(level: LogLevel.all);

  test('GraphQlPageProvider correctly paginates results', () async {
    await Config.init();
    const ChatId chatId = ChatId('99404e9a-e2e5-4b29-bd76-fff11dfc3796');

    final DriftProvider database = DriftProvider.memory();
    final ChatItemDriftProvider itemDriftProvider =
        ChatItemDriftProvider(database);

    final GraphQlProvider graphQlProvider = MockGraphQlProvider();

    Future<GetMessages$Query> chatItems({
      int? first,
      int? after,
      int? last,
      int? before,
    }) {
      DateTime at = DateTime.now().toUtc();

      Map<String, dynamic> message(String text) {
        at = at.add(const Duration(seconds: 1));

        return {
          'node': {
            '__typename': 'ChatMessage',
            'id': const Uuid().v4(),
            'chatId': chatId.val,
            'author': {
              '__typename': 'User',
              'id': '8105f99f-ab28-45d0-b206-87c227b13869',
              'num': '4737639025920649',
              'name': 'Nikita',
              'mutualContactsCount': 0,
              'contacts': [],
              'online': {'__typename': 'UserOnline'},
              'presence': 'PRESENT',
              'status': '08:00 - 16:00 UTC',
              'isDeleted': false,
              'dialog': null,
              'isBlocked': {
                'record': null,
                'ver':
                    '0311693284050424812357956900349787974580001690984416675657'
              },
              'ver':
                  '0311693284050424812357956900349787974580000000000000000000'
            },
            'at': at.toIso8601String(),
            'ver': '31170824792200248681521974534461104046',
            'repliesTo': [],
            'text': text,
            'editedAt': null,
            'attachments': []
          },
          'cursor': text,
        };
      }

      final items = List.generate(100, (i) => message('$i'))
          .skip(after ?? 0)
          .take(first ?? 100)
          .toList();

      return Future.value(
        GetMessages$Query.fromJson(
          {
            'chat': {
              'items': {
                'edges': items,
                'pageInfo': {
                  '__typename': 'PageInfo',
                  'endCursor': '${(first ?? 0) + (after ?? 0)}',
                  'hasNextPage': (first ?? 0) + (after ?? 0) < 100,
                  'startCursor': '${after ?? 0}',
                  'hasPreviousPage': false
                }
              }
            }
          },
        ),
      );
    }

    when(graphQlProvider.chatItems(chatId, first: 10))
        .thenAnswer((_) => chatItems(first: 10));

    when(graphQlProvider.chatItems(
      chatId,
      first: 10,
      after: const ChatItemsCursor('10'),
    )).thenAnswer((_) => chatItems(first: 10, after: 10));

    when(graphQlProvider.chatItems(
      chatId,
      first: 10,
      after: const ChatItemsCursor('20'),
    )).thenAnswer((_) => chatItems(first: 10, after: 20));

    when(graphQlProvider.chatItems(
      chatId,
      first: 10,
      after: const ChatItemsCursor('30'),
    )).thenAnswer((_) => chatItems(first: 10, after: 30));

    when(graphQlProvider.chatItems(
      chatId,
      first: 10,
      after: const ChatItemsCursor('40'),
    )).thenAnswer((_) => chatItems(first: 10, after: 40));

    when(graphQlProvider.chatItems(
      chatId,
      first: 10,
      after: const ChatItemsCursor('50'),
    )).thenAnswer((_) => chatItems(first: 10, after: 50));

    when(graphQlProvider.chatItems(
      chatId,
      first: 10,
      after: const ChatItemsCursor('60'),
    )).thenAnswer((_) => chatItems(first: 10, after: 60));

    when(graphQlProvider.chatItems(
      chatId,
      first: 10,
      after: const ChatItemsCursor('70'),
    )).thenAnswer((_) => chatItems(first: 10, after: 70));

    when(graphQlProvider.chatItems(
      chatId,
      first: 10,
      after: const ChatItemsCursor('80'),
    )).thenAnswer((_) => chatItems(first: 10, after: 80));

    when(graphQlProvider.chatItems(
      chatId,
      first: 10,
      after: const ChatItemsCursor('90'),
    )).thenAnswer((_) => chatItems(first: 10, after: 90));

    final Pagination<DtoChatItem, ChatItemsCursor, ChatItemId> pagination =
        Pagination(
      perPage: 10,
      onKey: (i) => i.value.id,
      provider: DriftGraphQlPageProvider(
        graphQlProvider:
            GraphQlPageProvider<DtoChatItem, ChatItemsCursor, ChatItemId>(
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
        driftProvider: DriftPageProvider(
          onKey: (e) => e.value.id,
          onCursor: (e) => e?.cursor,
          fetch: ({
            ChatItemId? around,
            required int before,
            required int after,
          }) {
            return itemDriftProvider.watch(
              chatId,
              before: before,
              after: after,
              // around: around,
            );
          },
        ),
      ),
      compare: (a, b) => a.value.key.compareTo(b.value.key),
    );

    await pagination.around();
    expect(pagination.items.length, 10);
    expect(pagination.hasPrevious.value, false);
    expect(pagination.hasNext.value, true);

    await pagination.next();
    expect(pagination.items.length, 20);

    await pagination.previous();
    expect(pagination.items.length, 20);

    await pagination.next();
    expect(pagination.items.length, 30);

    await pagination.next();
    expect(pagination.items.length, 40);

    await pagination.next();
    expect(pagination.items.length, 50);

    await pagination.next();
    expect(pagination.items.length, 60);

    await pagination.next();
    expect(pagination.items.length, 70);

    await pagination.next();
    expect(pagination.items.length, 80);

    await pagination.next();
    expect(pagination.items.length, 90);
    expect(pagination.hasNext.value, true);

    await pagination.next();
    expect(pagination.items.length, 100);
    expect(
      pagination.items.values.map((e) => (e.value as ChatMessage).text?.val),
      List.generate(100, (i) => '$i'),
    );
    expect(pagination.hasPrevious.value, false);
    expect(pagination.hasNext.value, false);
  });
}

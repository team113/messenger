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

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/api/backend/extension/page_info.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/store/model/chat_item.dart';
import 'package:messenger/store/model/page_info.dart';
import 'package:messenger/store/pagination.dart';
import 'package:messenger/store/pagination/graphql.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'pagination_test.mocks.dart';

@GenerateNiceMocks([MockSpec<GraphQlProvider>()])
void main() async {
  test('Pagination correctly invokes its methods', () async {
    final Pagination<int, int, int> pagination = Pagination(
      perPage: 4,
      provider: _ListPageProvider(),
      onKey: (i) => i,
      compare: (a, b) => a.compareTo(b),
    );

    await pagination.around(cursor: 20);
    expect(pagination.items.length, 4);
    expect(pagination.items.values, [18, 19, 20, 21]);
    expect(pagination.hasPrevious.value, true);
    expect(pagination.hasNext.value, true);

    await pagination.next();
    expect(pagination.items.length, 8);
    expect(pagination.items.values, [18, 19, 20, 21, 22, 23, 24, 25]);
    expect(pagination.hasPrevious.value, true);
    expect(pagination.hasNext.value, true);

    await pagination.previous();
    expect(pagination.items.length, 12);
    expect(pagination.items.values, [
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
    ]);
    expect(pagination.hasPrevious.value, true);
    expect(pagination.hasNext.value, true);
  });

  test('GraphQlPageProvider correctly paginates results', () async {
    await Config.init();
    const ChatId chatId = ChatId('99404e9a-e2e5-4b29-bd76-fff11dfc3796');

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
                    '0311693284050424812357956900349787974580001690984416675657',
              },
              'ver':
                  '0311693284050424812357956900349787974580000000000000000000',
            },
            'at': at.toIso8601String(),
            'ver': '31170824792200248681521974534461104046',
            'repliesTo': [],
            'text': text,
            'editedAt': null,
            'attachments': [],
          },
          'cursor': text,
        };
      }

      final items = List.generate(
        100,
        (i) => message('$i'),
      ).skip(after ?? 0).take(first ?? 100).toList();

      return Future.value(
        GetMessages$Query.fromJson({
          'chat': {
            'items': {
              'edges': items,
              'pageInfo': {
                '__typename': 'PageInfo',
                'endCursor': '${(first ?? 0) + (after ?? 0)}',
                'hasNextPage': (first ?? 0) + (after ?? 0) < 100,
                'startCursor': '${after ?? 0}',
                'hasPreviousPage': false,
              },
            },
          },
        }),
      );
    }

    when(
      graphQlProvider.chatItems(chatId, first: 10),
    ).thenAnswer((_) => chatItems(first: 10));

    when(
      graphQlProvider.chatItems(
        chatId,
        first: 10,
        after: const ChatItemsCursor('10'),
      ),
    ).thenAnswer((_) => chatItems(first: 10, after: 10));

    when(
      graphQlProvider.chatItems(
        chatId,
        first: 10,
        after: const ChatItemsCursor('20'),
      ),
    ).thenAnswer((_) => chatItems(first: 10, after: 20));

    when(
      graphQlProvider.chatItems(
        chatId,
        first: 10,
        after: const ChatItemsCursor('30'),
      ),
    ).thenAnswer((_) => chatItems(first: 10, after: 30));

    when(
      graphQlProvider.chatItems(
        chatId,
        first: 10,
        after: const ChatItemsCursor('40'),
      ),
    ).thenAnswer((_) => chatItems(first: 10, after: 40));

    when(
      graphQlProvider.chatItems(
        chatId,
        first: 10,
        after: const ChatItemsCursor('50'),
      ),
    ).thenAnswer((_) => chatItems(first: 10, after: 50));

    when(
      graphQlProvider.chatItems(
        chatId,
        first: 10,
        after: const ChatItemsCursor('60'),
      ),
    ).thenAnswer((_) => chatItems(first: 10, after: 60));

    when(
      graphQlProvider.chatItems(
        chatId,
        first: 10,
        after: const ChatItemsCursor('70'),
      ),
    ).thenAnswer((_) => chatItems(first: 10, after: 70));

    when(
      graphQlProvider.chatItems(
        chatId,
        first: 10,
        after: const ChatItemsCursor('80'),
      ),
    ).thenAnswer((_) => chatItems(first: 10, after: 80));

    when(
      graphQlProvider.chatItems(
        chatId,
        first: 10,
        after: const ChatItemsCursor('90'),
      ),
    ).thenAnswer((_) => chatItems(first: 10, after: 90));

    final Pagination<DtoChatItem, ChatItemsCursor, ChatItemKey> pagination =
        Pagination(
          perPage: 10,
          onKey: (i) => i.value.key,
          provider:
              GraphQlPageProvider<DtoChatItem, ChatItemsCursor, ChatItemKey>(
                fetch: ({after, before, first, last}) async {
                  final q = await graphQlProvider.chatItems(
                    chatId,
                    first: first,
                    after: after,
                    last: last,
                    before: before,
                  );

                  final PageInfo<ChatItemsCursor> info = q.chat!.items.pageInfo
                      .toModel((c) => ChatItemsCursor(c));
                  return Page(
                    RxList(q.chat!.items.edges.map((e) => e.toDto()).toList()),
                    PageInfo<ChatItemsCursor>(
                      hasNext: info.hasNext,
                      hasPrevious: info.hasPrevious,
                      startCursor: info.startCursor,
                      endCursor: info.endCursor,
                    ),
                  );
                },
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

class _ListPageProvider implements PageProvider<int, int, int> {
  final List<int> _items = List.generate(50, (i) => i);

  @override
  Future<Page<int, int>?> init(int? item, int count) async => null;

  @override
  void dispose() {
    // No-op.
  }

  @override
  FutureOr<Page<int, int>> around(int? item, int? cursor, int count) {
    final int half = count ~/ 2;

    cursor ??= half;

    int before = half;
    if (cursor - before < 0) {
      before = cursor;
    }

    int after = half;
    if (cursor + after > _items.length) {
      after = _items.length - cursor;
    }

    return Page(
      RxList(_items.skip(cursor - before).take(before + after).toList()),
      PageInfo<int>(
        hasPrevious: cursor - before > 0,
        hasNext: cursor + after < _items.length,
        startCursor: cursor - before,
        endCursor: cursor + after - 1,
      ),
    );
  }

  @override
  FutureOr<Page<int, int>> after(int? value, int? cursor, int count) {
    cursor ??= 0;

    if (cursor + 1 + count > _items.length) {
      count = _items.length - cursor - 1;
    }

    return Page(
      RxList(_items.skip(cursor + 1).take(count).toList()),
      PageInfo<int>(
        hasPrevious: cursor + 1 > 0,
        hasNext: cursor + 1 + count < _items.length,
        startCursor: cursor + 1,
        endCursor: cursor + count,
      ),
    );
  }

  @override
  FutureOr<Page<int, int>> before(int? item, int? cursor, int count) {
    cursor ??= 0;

    if (cursor - count < 0) {
      count = cursor;
    }

    return Page(
      RxList(_items.skip(cursor - count).take(count).toList()),
      PageInfo<int>(
        hasPrevious: cursor - count > 0,
        hasNext: cursor < _items.length,
        startCursor: cursor - count,
        endCursor: cursor - 1,
      ),
    );
  }

  @override
  Future<void> put(
    Iterable<int> items, {
    bool ignoreBounds = false,
    int Function(int, int)? compare,
  }) async {}

  @override
  Future<void> remove(int key) async {}

  @override
  Future<void> clear() async {}
}

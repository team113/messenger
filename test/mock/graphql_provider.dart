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
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/store/model/chat.dart';
import 'package:messenger/store/model/contact.dart';
import 'package:messenger/store/model/my_user.dart';

/// Mocked [GraphQlProvider] for sharing common behaviour between tests.
class MockedGraphQlProvider extends Fake implements GraphQlProvider {
  MockedGraphQlProvider();

  final StreamController<QueryResult> ongoingCallStream =
      StreamController<QueryResult>();

  final StreamController<QueryResult> chatEventsStream =
      StreamController<QueryResult>();

  @override
  void disconnect() {}

  @override
  Stream<QueryResult> incomingCallsTopEvents(int count) {
    Future.delayed(
      Duration.zero,
      () => ongoingCallStream.add(
        QueryResult.internal(
          source: QueryResultSource.network,
          data: {
            'incomingChatCallsTopEvents': {
              '__typename': 'SubscriptionInitialized',
              'ok': true,
            },
          },
          parserFn: (_) => null,
        ),
      ),
    );

    return ongoingCallStream.stream;
  }

  // @override
  // Future<Contacts$Query$ChatContacts> chatContacts({
  //   int? first,
  //   ChatContactsCursor? after,
  //   int? last,
  //   ChatContactsCursor? before,
  //   bool noFavorite = false,
  // }) async =>
  //     Contacts$Query.fromJson({
  //       'chatContacts': {
  //         'edges': [],
  //         'pageInfo': {
  //           'endCursor': 'endCursor',
  //           'hasNextPage': false,
  //           'startCursor': 'startCursor',
  //           'hasPreviousPage': false,
  //         },
  //         'ver': '0',
  //       }
  //     }).chatContacts;

  // @override
  // Future<FavoriteContacts$Query$FavoriteChatContacts> favoriteChatContacts({
  //   int? first,
  //   FavoriteChatContactsCursor? after,
  //   int? last,
  //   FavoriteChatContactsCursor? before,
  // }) async =>
  //     FavoriteContacts$Query.fromJson({
  //       'favoriteChatContacts': {
  //         'edges': [],
  //         'pageInfo': {
  //           'endCursor': 'endCursor',
  //           'hasNextPage': false,
  //           'startCursor': 'startCursor',
  //           'hasPreviousPage': false,
  //         },
  //         'ver': '0',
  //       }
  //     }).favoriteChatContacts;

  @override
  Future<RecentChats$Query> recentChats({
    int? first,
    RecentChatsCursor? after,
    int? last,
    RecentChatsCursor? before,
    bool noFavorite = false,
    bool archived = false,
    bool? withOngoingCalls,
  }) async => RecentChats$Query.fromJson({
    'recentChats': {
      'edges': [],
      'pageInfo': {
        'endCursor': 'endCursor',
        'hasNextPage': false,
        'startCursor': 'startCursor',
        'hasPreviousPage': false,
      },
    },
  });

  @override
  Future<FavoriteChats$Query> favoriteChats({
    int? first,
    FavoriteChatsCursor? after,
    int? last,
    FavoriteChatsCursor? before,
  }) async => FavoriteChats$Query.fromJson({
    'favoriteChats': {
      'edges': [],
      'pageInfo': {
        'endCursor': 'endCursor',
        'hasNextPage': false,
        'startCursor': 'startCursor',
        'hasPreviousPage': false,
      },
      'ver': '0',
    },
  });

  @override
  Future<Stream<QueryResult>> myUserEvents(
    Future<MyUserVersion?> Function()? getVer,
  ) async => const Stream.empty();

  @override
  Stream<QueryResult> contactsEvents(
    ChatContactsListVersion? Function()? getVer,
  ) => const Stream.empty();

  @override
  Stream<QueryResult> favoriteChatsEvents(
    FavoriteChatsListVersion? Function()? getVer,
  ) => const Stream.empty();
}

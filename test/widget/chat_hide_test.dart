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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/call.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/domain/service/session.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/provider/drift/account.dart';
import 'package:messenger/provider/drift/background.dart';
import 'package:messenger/provider/drift/blocklist.dart';
import 'package:messenger/provider/drift/call_credentials.dart';
import 'package:messenger/provider/drift/call_rect.dart';
import 'package:messenger/provider/drift/chat.dart';
import 'package:messenger/provider/drift/chat_credentials.dart';
import 'package:messenger/provider/drift/chat_item.dart';
import 'package:messenger/provider/drift/chat_member.dart';
import 'package:messenger/provider/drift/credentials.dart';
import 'package:messenger/provider/drift/draft.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/geolocation.dart';
import 'package:messenger/provider/drift/locks.dart';
import 'package:messenger/provider/drift/monolog.dart';
import 'package:messenger/provider/drift/my_user.dart';
import 'package:messenger/provider/drift/session.dart';
import 'package:messenger/provider/drift/settings.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/drift/version.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/blocklist.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/contact.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/session.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/chats/view.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/geo_provider.dart';
import 'chat_hide_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  final credentialsProvider = Get.put(CredentialsDriftProvider(common));
  final accountProvider = Get.put(AccountDriftProvider(common));
  final settingsProvider = Get.put(SettingsDriftProvider(common));
  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final userProvider = Get.put(UserDriftProvider(common, scoped));
  final chatItemProvider = Get.put(ChatItemDriftProvider(common, scoped));
  final chatMemberProvider = Get.put(ChatMemberDriftProvider(common, scoped));
  final chatProvider = Get.put(ChatDriftProvider(common, scoped));
  final backgroundProvider = Get.put(BackgroundDriftProvider(common));
  final blocklistProvider = Get.put(BlocklistDriftProvider(common, scoped));
  final callCredentialsProvider = Get.put(
    CallCredentialsDriftProvider(common, scoped),
  );
  final chatCredentialsProvider = Get.put(
    ChatCredentialsDriftProvider(common, scoped),
  );
  final callRectProvider = Get.put(CallRectDriftProvider(common, scoped));
  final draftProvider = Get.put(DraftDriftProvider(common, scoped));
  final monologProvider = Get.put(MonologDriftProvider(common));
  final versionProvider = Get.put(VersionDriftProvider(common));
  final sessionProvider = Get.put(SessionDriftProvider(common, scoped));
  final geoProvider = Get.put(GeoLocationDriftProvider(common));
  final locksProvider = Get.put(LockDriftProvider(common));

  var graphQlProvider = Get.put(MockGraphQlProvider());
  when(graphQlProvider.connected).thenReturn(RxBool(true));
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(graphQlProvider.recentChatsTopEvents(3)).thenAnswer(
    (_) => Stream.value(
      QueryResult.internal(
        source: QueryResultSource.network,
        data: {
          'recentChatsTopEvents': {
            '__typename': 'SubscriptionInitialized',
            'ok': true,
          },
        },
        parserFn: (_) => null,
      ),
    ),
  );
  when(
    graphQlProvider.incomingCallsTopEvents(3),
  ).thenAnswer((_) => const Stream.empty());

  when(
    graphQlProvider.favoriteChatsEvents(any),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.myUserEvents(any),
  ).thenAnswer((_) async => const Stream.empty());
  when(
    graphQlProvider.sessionsEvents(any),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.blocklistEvents(any),
  ).thenAnswer((_) => const Stream.empty());

  when(
    graphQlProvider.getUser(any),
  ).thenAnswer((_) => Future.value(GetUser$Query.fromJson({'user': null})));
  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  AuthService authService = Get.put(
    AuthService(
      AuthRepository(graphQlProvider, myUserProvider, credentialsProvider),
      credentialsProvider,
      accountProvider,
      locksProvider,
    ),
  );

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

  authService.init();

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      theme: Themes.light(),
      home: Builder(
        builder: (BuildContext context) {
          router.context = context;
          return Scaffold(body: child);
        },
      ),
    );
  }

  testWidgets('ChatsTabView successfully hides a chat', (
    WidgetTester tester,
  ) async {
    final StreamController<QueryResult> chatEvents = StreamController();
    when(
      graphQlProvider.chatEvents(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        any,
        any,
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(graphQlProvider.contactsEvents(any)).thenAnswer(
      (_) => Stream.fromIterable([
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'chatContactsEvents': {
              '__typename': 'ChatContactsList',
              'chatContacts': {'nodes': [], 'ver': '0'},
              'favoriteChatContacts': {'nodes': []},
            },
          },
        ),
      ]),
    );
    when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

    when(
      graphQlProvider.hideChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
    ).thenAnswer((_) {
      var event = {
        '__typename': 'ChatEventsVersioned',
        'events': [
          {
            '__typename': 'EventChatHidden',
            'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
            'at': DateTime.now().toString(),
          },
        ],
        'ver': '1',
      };

      chatEvents.add(
        QueryResult.internal(
          data: {'chatEvents': event},
          parserFn: (_) => null,
          source: null,
        ),
      );

      return Future.value(
        HideChat$Mutation.fromJson({'hideChat': event}).hideChat
            as HideChat$Mutation$HideChat$ChatEventsVersioned,
      );
    });

    when(
      graphQlProvider.unfavoriteChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
    ).thenAnswer((_) => Future.value(null));

    when(
      graphQlProvider.recentChats(
        first: anyNamed('first'),
        after: null,
        last: null,
        before: null,
        noFavorite: anyNamed('noFavorite'),
        withOngoingCalls: anyNamed('withOngoingCalls'),
      ),
    ).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(
      graphQlProvider.favoriteChats(
        first: anyNamed('first'),
        after: null,
        last: null,
        before: null,
      ),
    ).thenAnswer(
      (_) => Future.value(FavoriteChats$Query.fromJson(favoriteChats)),
    );

    when(graphQlProvider.incomingCalls()).thenAnswer(
      (_) => Future.value(
        IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []}),
      ),
    );

    when(
      graphQlProvider.incomingCallsTopEvents(3),
    ).thenAnswer((_) => const Stream.empty());

    when(
      graphQlProvider.getBlocklist(
        first: anyNamed('first'),
        after: null,
        last: null,
        before: null,
      ),
    ).thenAnswer(
      (_) => Future.value(GetBlocklist$Query$Blocklist.fromJson(blacklist)),
    );

    when(
      graphQlProvider.chatMembers(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        first: anyNamed('first'),
      ),
    ).thenAnswer(
      (_) => Future.value(
        GetMembers$Query.fromJson({
          'chat': {
            'members': {
              'edges': [],
              'pageInfo': {
                'endCursor': 'endCursor',
                'hasNextPage': false,
                'startCursor': 'startCursor',
                'hasPreviousPage': false,
              },
            },
          },
        }),
      ),
    );

    SessionRepository sessionRepository = Get.put(
      SessionRepository(
        graphQlProvider,
        accountProvider,
        versionProvider,
        sessionProvider,
        geoProvider,
        MockedGeoLocationProvider(),
      ),
    );
    Get.put(SessionService(sessionRepository));

    UserRepository userRepository = UserRepository(
      graphQlProvider,
      userProvider,
    );
    BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
        graphQlProvider,
        blocklistProvider,
        userRepository,
        versionProvider,
        me: const UserId('me'),
      ),
    );
    Get.put(UserService(userRepository));

    Get.put(
      ContactService(
        Get.put<AbstractContactRepository>(
          ContactRepository(
            graphQlProvider,
            userRepository,
            versionProvider,
            me: const UserId('me'),
          ),
        ),
      ),
    );

    final myUserRepository = Get.put<AbstractMyUserRepository>(
      MyUserRepository(
        graphQlProvider,
        myUserProvider,
        blocklistRepository,
        userRepository,
        accountProvider,
      ),
    );
    Get.put(MyUserService(authService, myUserRepository));

    final settingsRepository = Get.put<AbstractSettingsRepository>(
      SettingsRepository(
        const UserId('me'),
        settingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );

    final callRepository = Get.put<AbstractCallRepository>(
      CallRepository(
        graphQlProvider,
        userRepository,
        callCredentialsProvider,
        chatCredentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
    );
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        chatProvider,
        chatItemProvider,
        chatMemberProvider,
        callRepository,
        draftProvider,
        userRepository,
        versionProvider,
        monologProvider,
        me: const UserId('me'),
      ),
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    Get.put(CallService(authService, chatService, callRepository));

    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() => Future.delayed(1.milliseconds));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    await tester.pumpWidget(
      createWidgetForTesting(child: const ChatsTabView()),
    );

    expect(find.text('chatname'), findsOneWidget);

    await tester.longPress(
      find.byKey(const Key('Chat_0d72d245-8425-467a-9ebd-082d4f47850b')),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('HideChatButton')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('Proceed')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('chatname'), findsNothing);

    verify(
      graphQlProvider.hideChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
    );

    await Future.wait([common.close(), scoped.close()]);
    await Get.deleteAll(force: true);
  });
}

final chatData = {
  'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
  'name': 'chatname',
  'avatar': null,
  'members': {'nodes': [], 'totalCount': 0},
  'kind': 'GROUP',
  'isHidden': false,
  'muted': null,
  'directLink': null,
  'createdAt': '2021-12-15T15:11:18.316846+00:00',
  'updatedAt': '2021-12-15T15:11:18.316846+00:00',
  'lastReads': [],
  'lastDelivery': '1970-01-01T00:00:00+00:00',
  'lastItem': null,
  'lastReadItem': null,
  'unreadCount': 0,
  'totalCount': 0,
  'ongoingCall': null,
  'ver': '0',
};

final recentChats = {
  'recentChats': {
    'edges': [
      {'node': chatData, 'cursor': 'cursor'},
    ],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    },
  },
};

final favoriteChats = {
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
};

final chatContacts = {
  'chatContacts': {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    },
    'ver': '0',
  },
};

final favoriteChatContacts = {
  'favoriteChatContacts': {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    },
    'ver': '0',
  },
};

final blacklist = {
  'edges': [],
  'pageInfo': {
    'endCursor': 'endCursor',
    'hasNextPage': false,
    'startCursor': 'startCursor',
    'hasPreviousPage': false,
  },
};

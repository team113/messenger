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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql/client.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/my_user.dart';
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
import 'package:messenger/provider/drift/locks.dart';
import 'package:messenger/provider/drift/monolog.dart';
import 'package:messenger/provider/drift/my_user.dart';
import 'package:messenger/provider/drift/secret.dart';
import 'package:messenger/provider/drift/settings.dart';
import 'package:messenger/provider/drift/slugs.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/drift/version.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/blocklist.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/info/controller.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/platform_utils.dart';
import 'chat_rename_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GraphQlProvider>(),
  MockSpec<PlatformRouteInformationProvider>(),
])
void main() async {
  PlatformUtils = PlatformUtilsMock();
  TestWidgetsFlutterBinding.ensureInitialized();
  Config.disableInfiniteAnimations = true;

  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  final settingsProvider = Get.put(SettingsDriftProvider(common));
  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final credentialsProvider = Get.put(CredentialsDriftProvider(common));
  final accountProvider = Get.put(AccountDriftProvider(common));
  final locksProvider = Get.put(LockDriftProvider(common));
  final secretsProvider = Get.put(RefreshSecretDriftProvider(common));
  final slugProvider = Get.put(SlugDriftProvider(common));

  await accountProvider.upsert(const UserId('me'));
  await credentialsProvider.upsert(
    Credentials(
      AccessToken(
        const AccessTokenSecret('token'),
        PreciseDateTime.now().add(const Duration(days: 1)),
      ),
      RefreshToken(
        const RefreshTokenSecret('token'),
        PreciseDateTime.now().add(const Duration(days: 1)),
      ),
      Session(
        id: const SessionId('me'),
        ip: IpAddress('localhost'),
        userAgent: UserAgent(''),
        lastActivatedAt: PreciseDateTime.now(),
        siteDomain: SiteDomain(''),
      ),
      const UserId('me'),
    ),
  );

  var graphQlProvider = MockGraphQlProvider();
  when(
    graphQlProvider.onStart,
  ).thenReturn(InternalFinalCallback(callback: () {}));
  when(
    graphQlProvider.onDelete,
  ).thenReturn(InternalFinalCallback(callback: () {}));
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(
    graphQlProvider.recentChatsTopEvents(3),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.recentChatsTopEvents(3, archived: true),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.incomingCallsTopEvents(3),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.blocklistEvents(any),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.favoriteChatsEvents(any),
  ).thenAnswer((_) => const Stream.empty());
  Get.put<GraphQlProvider>(graphQlProvider);

  when(graphQlProvider.getUser(any)).thenAnswer(
    (_) => Future.value(GetUser$Query.fromJson({'user': null}).user),
  );
  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  AuthService authService = AuthService(
    AuthRepository(
      graphQlProvider,
      myUserProvider,
      credentialsProvider,
      slugProvider,
    ),
    credentialsProvider,
    accountProvider,
    locksProvider,
    secretsProvider,
  );

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

  authService.init();

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
  final monologProvider = Get.put(MonologDriftProvider(common, scoped));
  final versionProvider = Get.put(VersionDriftProvider(common));

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      theme: Themes.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('ChatView successfully changes chat name', (
    WidgetTester tester,
  ) async {
    when(
      graphQlProvider.recentChatsTopEvents(3),
    ).thenAnswer((_) => const Stream.empty());
    when(
      graphQlProvider.recentChatsTopEvents(3, archived: true),
    ).thenAnswer((_) => const Stream.empty());

    final StreamController<QueryResult> chatEvents = StreamController();
    when(
      graphQlProvider.chatEvents(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        any,
        any,
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      graphQlProvider.getChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
    ).thenAnswer(
      (_) => Future.value(GetChat$Query.fromJson({'chat': chatData})),
    );

    when(
      graphQlProvider.chatItems(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        last: 50,
      ),
    ).thenAnswer(
      (_) => Future.value(
        GetMessages$Query.fromJson({
          'chat': {
            'items': {'edges': []},
          },
        }),
      ),
    );

    when(
      graphQlProvider.recentChats(
        first: anyNamed('first'),
        after: null,
        last: null,
        before: null,
        noFavorite: anyNamed('noFavorite'),
        archived: anyNamed('archived'),
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

    when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

    when(graphQlProvider.incomingCalls()).thenAnswer(
      (_) => Future.value(
        IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []}),
      ),
    );
    when(
      graphQlProvider.incomingCallsTopEvents(3),
    ).thenAnswer((_) => const Stream.empty());

    when(
      graphQlProvider.renameChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ChatName('newname'),
      ),
    ).thenAnswer((_) {
      var event = {
        '__typename': 'ChatEventsVersioned',
        'events': [
          {
            '__typename': 'EventChatRenamed',
            'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
            'name': 'newname',
            'byUser': {
              '__typename': 'User',
              'id': '0d72d245-8425-467a-9ebd-082d4f47850a',
              'num': '1234567890123456',
              'login': null,
              'name': null,
              'emails': {'confirmed': []},
              'phones': {'confirmed': []},
              'chatDirectLink': null,
              'hasPassword': false,
              'unreadChatsCount': 0,
              'ver': '0',
              'presence': 'AWAY',
              'online': {'__typename': 'UserOnline'},
              'mutualContactsCount': 0,
              'contacts': [],
              'isDeleted': false,
              'isBlocked': {'ver': '0'},
            },
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
        RenameChat$Mutation.fromJson({'renameChat': event}).renameChat
            as RenameChat$Mutation$RenameChat$ChatEventsVersioned,
      );
    });

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

    when(
      graphQlProvider.myUserEvents(any),
    ).thenAnswer((_) async => const Stream.empty());

    when(
      graphQlProvider.sessionsEvents(any),
    ).thenAnswer((_) => const Stream.empty());

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(
          AuthRepository(
            Get.find(),
            myUserProvider,
            credentialsProvider,
            slugProvider,
          ),
        ),
        credentialsProvider,
        accountProvider,
        locksProvider,
        secretsProvider,
      ),
    );

    router = RouterState(authService);
    router.provider = MockPlatformRouteInformationProvider();

    authService.init();

    UserRepository userRepository = Get.put(
      UserRepository(graphQlProvider, userProvider, me: const UserId('me')),
    );
    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        backgroundProvider,
        callRectProvider,
        me: const UserId('me'),
      ),
    );
    final callRepository = CallRepository(
      graphQlProvider,
      userRepository,
      callCredentialsProvider,
      chatCredentialsProvider,
      settingsRepository,
      me: const UserId('me'),
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
        slugProvider,
        me: const UserId('me'),
      ),
    );

    Get.put(UserService(userRepository));
    ChatService chatService = Get.put(ChatService(chatRepository, authService));
    Get.put(CallService(authService, chatService, callRepository));

    BlocklistRepository blocklistRepository = BlocklistRepository(
      graphQlProvider,
      blocklistProvider,
      userRepository,
      versionProvider,
      me: const UserId('me'),
    );

    MyUserRepository myUserRepository = Get.put(
      MyUserRepository(
        graphQlProvider,
        myUserProvider,
        blocklistRepository,
        userRepository,
        accountProvider,
        me: const UserId('me'),
      ),
    );
    Get.put(MyUserService(authService, myUserRepository));

    await tester.pumpWidget(
      createWidgetForTesting(
        child: const ChatInfoView(
          ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ),
      ),
    );

    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() => Future.delayed(1.milliseconds));
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));

    var field = find.byKey(const Key('RenameChatField'));
    expect(field, findsOneWidget);

    await tester.tap(field);
    await tester.pumpAndSettle();

    await tester.enterText(field, 'newname');
    await tester.pumpAndSettle();

    expect(find.text('newname'), findsNWidgets(1));

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    verify(
      graphQlProvider.renameChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ChatName('newname'),
      ),
    );

    expect(find.text('newname'), findsNWidgets(2));

    await Future.wait([common.close(), scoped.close()]);
    await Get.deleteAll(force: true);
  });

  await myUserProvider.clear();
  await chatProvider.clear();
}

final chatData = {
  'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
  'name': 'startname',
  'avatar': null,
  'members': {'nodes': [], 'totalCount': 0},
  'kind': 'GROUP',
  'isHidden': false,
  'isArchived': false,
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

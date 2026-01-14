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
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
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
import 'package:messenger/provider/drift/secret.dart';
import 'package:messenger/provider/drift/session.dart';
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
import 'package:messenger/store/contact.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/session.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/user/view.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/geo_provider.dart';
import 'user_profile_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GraphQlProvider>(),
  MockSpec<PlatformRouteInformationProvider>(),
])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  final credentialsProvider = Get.put(CredentialsDriftProvider(common));
  final accountProvider = Get.put(AccountDriftProvider(common));
  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final locksProvider = Get.put(LockDriftProvider(common));
  final secretsProvider = Get.put(RefreshSecretDriftProvider(common));
  final slugProvider = Get.put(SlugDriftProvider(common));

  await accountProvider.upsert(const UserId('me'));

  final graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.connected).thenReturn(RxBool(true));
  when(
    graphQlProvider.onStart,
  ).thenReturn(InternalFinalCallback(callback: () {}));
  when(
    graphQlProvider.onDelete,
  ).thenReturn(InternalFinalCallback(callback: () {}));
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(
    graphQlProvider.favoriteChatsEvents(any),
  ).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.getUser(any)).thenAnswer(
    (_) => Future.value(GetUser$Query.fromJson({'user': null}).user),
  );
  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  final AuthService authService = AuthService(
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

  await authService.init();

  final settingsProvider = Get.put(SettingsDriftProvider(common));
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
  final sessionProvider = Get.put(SessionDriftProvider(common, scoped));
  final geoProvider = Get.put(GeoLocationDriftProvider(common));

  Get.put(myUserProvider);
  Get.put(userProvider);
  Get.put<GraphQlProvider>(graphQlProvider);
  Get.put(credentialsProvider);
  Get.put(chatProvider);
  Get.put(callCredentialsProvider);

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

  testWidgets(
    'UserView correctly displays data and implements correct functionality',
    (WidgetTester tester) async {
      final StreamController<QueryResult> contactEvents = StreamController();
      when(
        graphQlProvider.contactsEvents(any),
      ).thenAnswer((_) => contactEvents.stream);

      when(
        graphQlProvider.recentChatsTopEvents(3),
      ).thenAnswer((_) => const Stream.empty());
      when(
        graphQlProvider.recentChatsTopEvents(3, archived: true),
      ).thenAnswer((_) => const Stream.empty());
      when(
        graphQlProvider.keepOnline(),
      ).thenAnswer((_) => const Stream.empty());
      when(
        graphQlProvider.myUserEvents(any),
      ).thenAnswer((_) async => const Stream.empty());
      when(
        graphQlProvider.blocklistEvents(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        graphQlProvider.sessionsEvents(any),
      ).thenAnswer((_) => const Stream.empty());

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
      ).thenAnswer(
        (_) => Future.value(RecentChats$Query.fromJson(recentChats)),
      );

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
        graphQlProvider.myUserEvents(any),
      ).thenAnswer((_) async => const Stream.empty());

      when(
        graphQlProvider.userEvents(
          const UserId('9188c6b1-c2d7-4af2-a662-f68c0a00a1be'),
          any,
        ),
      ).thenAnswer((_) async => const Stream.empty());

      when(graphQlProvider.incomingCalls()).thenAnswer(
        (_) => Future.value(
          IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []}),
        ),
      );
      when(
        graphQlProvider.incomingCallsTopEvents(3),
      ).thenAnswer((_) => const Stream.empty());

      when(graphQlProvider.getMyUser()).thenAnswer(
        (_) => Future.value(GetMyUser$Query.fromJson({'myUser': userData})),
      );

      final StreamController<QueryResult> myUserEvents = StreamController();
      when(
        graphQlProvider.myUserEvents(any),
      ).thenAnswer((_) async => myUserEvents.stream);

      when(
        graphQlProvider.getUser(
          const UserId('9188c6b1-c2d7-4af2-a662-f68c0a00a1be'),
        ),
      ).thenAnswer(
        (_) => Future.value(GetUser$Query.fromJson({'user': newUserData}).user),
      );

      final authService = Get.put(
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
      await authService.init();

      final userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, me: const UserId('me')),
      );
      final BlocklistRepository blocklistRepository = Get.put(
        BlocklistRepository(
          graphQlProvider,
          blocklistProvider,
          userRepository,
          versionProvider,
          me: const UserId('me'),
        ),
      );
      Get.put(UserService(userRepository));

      final myUserRepository = Get.put(
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

      final sessionRepository = Get.put(
        SessionRepository(
          graphQlProvider,
          accountProvider,
          versionProvider,
          sessionProvider,
          geoProvider,
          MockedGeoLocationProvider(),
          me: const UserId('me'),
        ),
      );
      Get.put(SessionService(sessionRepository));

      final settingsRepository = Get.put(
        SettingsRepository(
          settingsProvider,
          backgroundProvider,
          callRectProvider,
          me: const UserId('me'),
        ),
      );
      final contactRepository = Get.put(
        ContactRepository(
          graphQlProvider,
          userRepository,
          versionProvider,
          me: const UserId('me'),
        ),
      );
      Get.put(ContactService(contactRepository));
      userRepository.getContact = contactRepository.get;

      final callRepository = Get.put(
        CallRepository(
          graphQlProvider,
          userRepository,
          callCredentialsProvider,
          chatCredentialsProvider,
          settingsRepository,
          me: const UserId('me'),
        ),
      );
      final chatRepository = Get.put(
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
      final chatService = Get.put(ChatService(chatRepository, authService));

      Get.put(CallService(authService, chatService, callRepository));

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const UserView(UserId('9188c6b1-c2d7-4af2-a662-f68c0a00a1be')),
        ),
      );

      await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('user name'), findsAny);
      expect(find.byKey(const Key('Present')), findsOneWidget);

      await tester.dragUntilVisible(
        find.byKey(const Key('NumCopyable')),
        find.byKey(const Key('UserScrollable')),
        const Offset(1, 1),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('5769hyphen2360hyphen9862hyphen1822'), findsOneWidget);

      PlatformUtils.activityTimer?.cancel();

      await Future.wait([common.close(), scoped.close()]);
      await Get.deleteAll(force: true);
    },
  );
}

final recentChats = {
  'recentChats': {
    'edges': [],
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

final userData = {
  'id': '12345',
  'num': '1234567890123456',
  'login': 'login',
  'name': 'name',
  'emails': {'confirmed': [], 'unconfirmed': null},
  'phones': {'confirmed': [], 'unconfirmed': null},
  'hasPassword': true,
  'unreadChatsCount': 0,
  'ver': '0',
  'online': {'__typename': 'UserOnline'},
  'presence': 'AWAY',
};

final newUserData = {
  '__typename': 'User',
  'id': '9188c6b1-c2d7-4af2-a662-f68c0a00a1be',
  'num': '5769236098621822',
  'name': 'user name',
  'avatar': null,
  'callCover': null,
  'mutualContactsCount': 0,
  'contacts': [],
  'online': {
    '__typename': 'UserOffline',
    'lastSeenAt': '2022-03-14T12:55:28.415454+00:00',
  },
  'presence': 'PRESENT',
  'status': null,
  'isDeleted': false,
  'dialog': {'id': '004ac2ab-911e-4d67-8671-ebba02758807'},
  'isBlocked': {'ver': '2'},
  'ver': '1',
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

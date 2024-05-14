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

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/account.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/blocklist.dart';
import 'package:messenger/provider/hive/blocklist_sorting.dart';
import 'package:messenger/provider/hive/call_credentials.dart';
import 'package:messenger/provider/hive/call_rect.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_credentials.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/contact_sorting.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/favorite_chat.dart';
import 'package:messenger/provider/hive/favorite_contact.dart';
import 'package:messenger/provider/hive/session_data.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/monolog.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/recent_chat.dart';
import 'package:messenger/provider/hive/credentials.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/blocklist.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/contact.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/user/view.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'user_profile_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final DriftProvider database = DriftProvider(NativeDatabase.memory());

  Hive.init('./test/.temp_hive/user_profile_widget');

  var credentialsProvider = CredentialsHiveProvider();
  await credentialsProvider.init();
  final accountProvider = AccountHiveProvider();
  await accountProvider.init();
  final myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();

  accountProvider.set(const UserId('me'));

  final graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(graphQlProvider.favoriteChatsEvents(any)).thenAnswer(
    (_) => const Stream.empty(),
  );

  when(graphQlProvider.getUser(any))
      .thenAnswer((_) => Future.value(GetUser$Query.fromJson({'user': null})));
  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  final AuthService authService = AuthService(
    AuthRepository(
      graphQlProvider,
      myUserProvider,
      credentialsProvider,
    ),
    credentialsProvider,
    accountProvider,
  );
  authService.init();

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

  var contactProvider = ContactHiveProvider();
  await contactProvider.init();
  await contactProvider.clear();
  final userProvider = UserDriftProvider(database);
  var chatProvider = ChatHiveProvider();
  await chatProvider.init();
  await chatProvider.clear();
  var draftProvider = Get.put(DraftHiveProvider());
  await draftProvider.init();
  await draftProvider.clear();
  var mediaSettingsProvider = MediaSettingsHiveProvider();
  await mediaSettingsProvider.init();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  final callCredentialsProvider = CallCredentialsHiveProvider();
  await callCredentialsProvider.init();
  final chatCredentialsProvider = ChatCredentialsHiveProvider();
  await chatCredentialsProvider.init();
  var blockedUsersProvider = BlocklistHiveProvider();
  await blockedUsersProvider.init();
  var callRectProvider = CallRectHiveProvider();
  await callRectProvider.init();
  var monologProvider = MonologHiveProvider();
  await monologProvider.init();
  var recentChatProvider = RecentChatHiveProvider();
  await recentChatProvider.init();
  var favoriteChatProvider = FavoriteChatHiveProvider();
  await favoriteChatProvider.init();
  var sessionProvider = SessionDataHiveProvider();
  await sessionProvider.init();
  await sessionProvider.clear();
  var favoriteContactHiveProvider = Get.put(FavoriteContactHiveProvider());
  await favoriteContactHiveProvider.init();
  var contactSortingHiveProvider = Get.put(ContactSortingHiveProvider());
  await contactSortingHiveProvider.init();
  var blocklistSortingProvider = BlocklistSortingHiveProvider();
  await blocklistSortingProvider.init();

  Get.put(myUserProvider);
  Get.put(contactProvider);
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

    when(graphQlProvider.recentChatsTopEvents(3))
        .thenAnswer((_) => const Stream.empty());
    when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

    when(graphQlProvider.chatContacts(
      first: anyNamed('first'),
      noFavorite: true,
      before: null,
      after: null,
      last: null,
    )).thenAnswer((_) =>
        Future.value(Contacts$Query.fromJson(chatContacts).chatContacts));

    when(graphQlProvider.favoriteChatContacts(
      first: anyNamed('first'),
      before: null,
      after: null,
      last: null,
    )).thenAnswer(
      (_) => Future.value(FavoriteContacts$Query.fromJson(favoriteChatContacts)
          .favoriteChatContacts),
    );

    when(graphQlProvider.myUserEvents(any)).thenAnswer(
      (_) => const Stream.empty(),
    );

    when(graphQlProvider.recentChats(
      first: anyNamed('first'),
      after: null,
      last: null,
      before: null,
      noFavorite: anyNamed('noFavorite'),
      withOngoingCalls: anyNamed('withOngoingCalls'),
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(graphQlProvider.favoriteChats(
      first: anyNamed('first'),
      after: null,
      last: null,
      before: null,
    )).thenAnswer(
        (_) => Future.value(FavoriteChats$Query.fromJson(favoriteChats)));

    when(graphQlProvider.getBlocklist(
      first: anyNamed('first'),
      after: null,
      last: null,
      before: null,
    )).thenAnswer(
      (_) => Future.value(GetBlocklist$Query$Blocklist.fromJson(blacklist)),
    );

    when(graphQlProvider.myUserEvents(any))
        .thenAnswer((realInvocation) => const Stream.empty());

    when(graphQlProvider.userEvents(
      const UserId('9188c6b1-c2d7-4af2-a662-f68c0a00a1be'),
      any,
    )).thenAnswer((_) async => const Stream.empty());

    when(graphQlProvider.incomingCalls()).thenAnswer((_) => Future.value(
        IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []})));
    when(graphQlProvider.incomingCallsTopEvents(3))
        .thenAnswer((_) => const Stream.empty());

    when(graphQlProvider.getMyUser()).thenAnswer(
      (_) => Future.value(GetMyUser$Query.fromJson({'myUser': userData})),
    );

    final StreamController<QueryResult> myUserEvents = StreamController();
    when(
      graphQlProvider.myUserEvents(any),
    ).thenAnswer((_) => myUserEvents.stream);

    when(graphQlProvider.createChatContact(
      name: UserName('user name'),
      records: [
        ChatContactRecord(
          userId: const UserId('9188c6b1-c2d7-4af2-a662-f68c0a00a1be'),
        )
      ],
    )).thenAnswer((_) {
      var event1 = {
        '__typename': 'EventChatContactCreated',
        'contactId': '9188c6b1-c2d7-4af2-a662-f68c0a00a1b2',
        'at': DateTime.now().toString(),
        'name': '1009422423626377'
      };

      var event2 = {
        '__typename': 'EventChatContactUserAdded',
        'contactId': '9188c6b1-c2d7-4af2-a662-f68c0a00a1b2',
        'at': DateTime.now().toString(),
        'user': {
          '__typename': 'User',
          'id': '9188c6b1-c2d7-4af2-a662-f68c0a00a1be',
          'num': '5769236098621822',
          'name': 'user name',
          'avatar': null,
          'callCover': null,
          'mutualContactsCount': 0,
          'contacts': [
            {
              'id': '9188c6b1-c2d7-4af2-a662-f68c0a00a1b2',
              'name': '1009422423626377',
            }
          ],
          'online': {
            '__typename': 'UserOffline',
            'lastSeenAt': '2022-03-14T12:55:28.415454+00:00'
          },
          'presence': 'PRESENT',
          'status': null,
          'isDeleted': false,
          'dialog': null,
          'isBlocked': {'ver': '5'},
          'ver': '4'
        },
      };

      contactEvents.add(QueryResult.internal(
        data: {
          'chatContactsEvents': {
            '__typename': 'ChatContactEventsVersioned',
            'events': [event1, event2],
            'ver': '5',
            'listVer': '5',
          }
        },
        parserFn: (_) => null,
        source: null,
      ));

      return Future.value(CreateChatContact$Mutation.fromJson({
        'createChatContact': {
          '__typename': 'ChatContactEventsVersioned',
          'events': [event1, event2],
          'ver': '6',
          'listVer': '6',
        }
      }).createChatContact as ChatContactEventsVersionedMixin?);
    });

    when(graphQlProvider.deleteChatContact(
      const ChatContactId('9188c6b1-c2d7-4af2-a662-f68c0a00a1b2'),
    )).thenAnswer((_) {
      var event = {
        '__typename': 'ChatContactEventsVersioned',
        'events': [
          {
            '__typename': 'EventChatContactDeleted',
            'contactId': '9188c6b1-c2d7-4af2-a662-f68c0a00a1b2',
            'at': '2022-03-21T12:58:29.700441900+00:00',
          }
        ],
        'ver': '7',
        'listVer': '7'
      };

      contactEvents.add(QueryResult.internal(
        data: {'chatContactsEvents': event},
        parserFn: (_) => null,
        source: null,
      ));

      return Future.value(
          DeleteChatContact$Mutation.fromJson({'deleteChatContact': event}));
    });

    when(graphQlProvider.chatContact(
      const ChatContactId('9188c6b1-c2d7-4af2-a662-f68c0a00a1b2'),
    )).thenAnswer(
      (_) => Future.value(GetContact$Query.fromJson({
        'chatContact': {
          'id': '9188c6b1-c2d7-4af2-a662-f68c0a00a1b2',
          'name': '1009422423626377',
          'users': [newUserData],
          'groups': [],
          'emails': [],
          'phones': [],
          'favoritePosition': null,
          'ver': '0',
        }
      })),
    );

    when(graphQlProvider.getUser(
      const UserId('9188c6b1-c2d7-4af2-a662-f68c0a00a1be'),
    )).thenAnswer(
      (_) => Future.value(GetUser$Query.fromJson({'user': newUserData})),
    );

    final authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(
          Get.find(),
          myUserProvider,
          credentialsProvider,
        )),
        credentialsProvider,
        accountProvider,
      ),
    );
    authService.init();

    final userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));
    final BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
        graphQlProvider,
        blockedUsersProvider,
        blocklistSortingProvider,
        userRepository,
        sessionProvider,
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
      ),
    );
    Get.put(MyUserService(authService, myUserRepository));

    final settingsRepository = Get.put(
      SettingsRepository(
        mediaSettingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );
    final contactRepository = Get.put(
      ContactRepository(
        graphQlProvider,
        contactProvider,
        favoriteContactHiveProvider,
        contactSortingHiveProvider,
        userRepository,
        sessionProvider,
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
        recentChatProvider,
        favoriteChatProvider,
        callRepository,
        draftProvider,
        userRepository,
        sessionProvider,
        monologProvider,
        me: const UserId('me'),
      ),
    );
    final chatService = Get.put(ChatService(chatRepository, authService));

    Get.put(CallService(authService, chatService, callRepository));

    await tester.pumpWidget(createWidgetForTesting(
      child: const UserView(UserId('9188c6b1-c2d7-4af2-a662-f68c0a00a1be')),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('user name'), findsAny);
    await tester.dragUntilVisible(
      find.byKey(const Key('NumCopyable')),
      find.byKey(const Key('UserScrollable')),
      const Offset(1, 1),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('Present')), findsOneWidget);
    expect(find.text('5769space2360space9862space1822'), findsOneWidget);

    await tester.tap(find.byKey(const Key('MoreButton')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('AddToContactsButton')));

    // TODO: This waits for lazy [Hive] boxes to finish receiving events, which
    //       should be done in a more strict way.
    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() => Future.delayed(1.milliseconds));
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('MoreButton')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    var deleteFromContacts = find.byKey(const Key('DeleteFromContactsButton'));
    expect(deleteFromContacts, findsOneWidget);
    await tester.tap(deleteFromContacts);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('MoreButton')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('AddToContactsButton')), findsOneWidget);

    PlatformUtils.activityTimer?.cancel();

    await database.close();
    await Get.deleteAll(force: true);
  });
}

final recentChats = {
  'recentChats': {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    }
  }
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
    'ver': '0'
  }
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
    'lastSeenAt': '2022-03-14T12:55:28.415454+00:00'
  },
  'presence': 'PRESENT',
  'status': null,
  'isDeleted': false,
  'dialog': {'id': '004ac2ab-911e-4d67-8671-ebba02758807'},
  'isBlocked': {'ver': '2'},
  'ver': '1'
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
  }
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
  }
};

final blacklist = {
  'edges': [],
  'pageInfo': {
    'endCursor': 'endCursor',
    'hasNextPage': false,
    'startCursor': 'startCursor',
    'hasPreviousPage': false,
  }
};

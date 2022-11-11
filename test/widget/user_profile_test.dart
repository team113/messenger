// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_call_credentials.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/contact.dart';
import 'package:messenger/store/model/contact.dart';
import 'package:messenger/store/model/my_user.dart';
import 'package:messenger/store/model/user.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/ui/page/home/page/user/view.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'user_profile_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/user_profile_widget');
  var recentChats = {
    'recentChats': {'nodes': []}
  };

  var userData = {
    'id': '12345',
    'num': '1234567890123456',
    'login': 'login',
    'name': 'name',
    'bio': 'bio',
    'emails': {'confirmed': [], 'unconfirmed': null},
    'phones': {'confirmed': [], 'unconfirmed': null},
    'gallery': {'nodes': []},
    'hasPassword': true,
    'unreadChatsCount': 0,
    'ver': '0',
    'online': {'__typename': 'UserOnline'},
    'presence': 'AWAY',
  };

  var newUserData = {
    '__typename': 'User',
    'id': '9188c6b1-c2d7-4af2-a662-f68c0a00a1be',
    'num': '5769236098621822',
    'name': 'user name',
    'bio': 'user bio',
    'avatar': null,
    'callCover': null,
    'gallery': {'nodes': []},
    'mutualContactsCount': 0,
    'online': {
      '__typename': 'UserOffline',
      'lastSeenAt': '2022-03-14T12:55:28.415454+00:00'
    },
    'presence': 'PRESENT',
    'status': null,
    'isDeleted': false,
    'dialog': {'id': '004ac2ab-911e-4d67-8671-ebba02758807'},
    'isBlacklisted': {'blacklisted': false, 'ver': '2'},
    'ver': '1'
  };

  var chatContactsData = {
    'chatContacts': {'nodes': [], 'ver': '0'}
  };

  var sessionProvider = SessionDataHiveProvider();
  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  AuthService authService =
      AuthService(AuthRepository(graphQlProvider), sessionProvider);
  await authService.init();
  await sessionProvider.init();

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  await myUserProvider.clear();
  var galleryItemProvider = GalleryItemHiveProvider();
  await galleryItemProvider.init();
  await galleryItemProvider.clear();
  var contactProvider = ContactHiveProvider();
  await contactProvider.init();
  await contactProvider.clear();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  await userProvider.clear();
  var chatProvider = ChatHiveProvider();
  await chatProvider.init();
  await chatProvider.clear();
  var mediaProvider = MediaSettingsHiveProvider();
  await mediaProvider.init();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  var credentialsProvider = ChatCallCredentialsHiveProvider();
  await credentialsProvider.init();

  Get.put(myUserProvider);
  Get.put(galleryItemProvider);
  Get.put(contactProvider);
  Get.put(userProvider);
  Get.put<GraphQlProvider>(graphQlProvider);
  Get.put(sessionProvider);
  Get.put(chatProvider);
  Get.put(credentialsProvider);

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(home: Builder(
      builder: (BuildContext context) {
        router.context = context;
        return Scaffold(body: child);
      },
    ));
  }

  testWidgets(
      'UserView correctly displays data and implements correct functionality',
      (WidgetTester tester) async {
    final StreamController<QueryResult> contactEvents = StreamController();
    when(
      graphQlProvider.contactsEvents(ChatContactsListVersion('0')),
    ).thenAnswer((_) => Future.value(contactEvents.stream));

    when(graphQlProvider.recentChatsTopEvents(3))
        .thenAnswer((_) => Future.value(const Stream.empty()));
    when(graphQlProvider.keepOnline())
        .thenAnswer((_) => Future.value(const Stream.empty()));

    when(graphQlProvider.chatContacts(
      first: 120,
      noFavorite: false,
      before: null,
      after: null,
      last: null,
    )).thenAnswer((_) =>
        Future.value((Contacts$Query.fromJson(chatContactsData).chatContacts)));

    when(graphQlProvider.myUserEvents(MyUserVersion('0'))).thenAnswer(
      (_) => Future.value(const Stream.empty()),
    );

    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer(
      (_) => Future.value(RecentChats$Query.fromJson(recentChats)),
    );

    when(graphQlProvider.contactsEvents(null))
        .thenAnswer((realInvocation) => Future.value(const Stream.empty()));

    when(graphQlProvider.myUserEvents(null))
        .thenAnswer((realInvocation) => Future.value(const Stream.empty()));

    when(graphQlProvider.userEvents(
      const UserId('9188c6b1-c2d7-4af2-a662-f68c0a00a1be'),
      UserVersion('1'),
    )).thenAnswer((realInvocation) => Future.value(const Stream.empty()));

    when(graphQlProvider.incomingCalls()).thenAnswer((_) => Future.value(
        IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []})));
    when(graphQlProvider.incomingCallsTopEvents(3))
        .thenAnswer((_) => Future.value(const Stream.empty()));

    when(graphQlProvider.getMyUser()).thenAnswer(
      (_) => Future.value(GetMyUser$Query.fromJson({'myUser': userData})),
    );

    final StreamController<QueryResult> myUserEvents = StreamController();
    when(
      graphQlProvider.myUserEvents(MyUserVersion('0')),
    ).thenAnswer((_) => Future.value(myUserEvents.stream));

    when(graphQlProvider.createChatContact(
        name: UserName('user name'),
        records: [
          ChatContactRecord(
              userId: const UserId('9188c6b1-c2d7-4af2-a662-f68c0a00a1be'))
        ])).thenAnswer((_) {
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
          'bio': 'user bio',
          'avatar': null,
          'callCover': null,
          'gallery': {'nodes': []},
          'mutualContactsCount': 0,
          'online': {
            '__typename': 'UserOffline',
            'lastSeenAt': '2022-03-14T12:55:28.415454+00:00'
          },
          'presence': 'PRESENT',
          'status': null,
          'isDeleted': false,
          'dialog': null,
          'isBlacklisted': {'blacklisted': false, 'ver': '5'},
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
        'ver': '3',
        'listVer': '3'
      };

      contactEvents.add(QueryResult.internal(
        data: {'chatContactsEvents': event},
        parserFn: (_) => null,
        source: null,
      ));

      return Future.value(
          DeleteChatContact$Mutation.fromJson({'deleteChatContact': event}));
    });

    when(graphQlProvider
            .getUser(const UserId('9188c6b1-c2d7-4af2-a662-f68c0a00a1be')))
        .thenAnswer(
            (_) => Future.value(GetUser$Query.fromJson({'user': newUserData})));

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    await authService.init();

    UserRepository userRepository =
        UserRepository(graphQlProvider, userProvider, galleryItemProvider);
    Get.put(UserService(userRepository));
    AbstractMyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      galleryItemProvider,
      userRepository,
    );
    Get.put(MyUserService(authService, myUserRepository));

    ContactRepository contactRepository = ContactRepository(
        graphQlProvider, contactProvider, userRepository, sessionProvider);
    Get.put(ContactService(contactRepository));

    CallRepository callRepository = CallRepository(
      graphQlProvider,
      userRepository,
      credentialsProvider,
    );
    ChatRepository chatRepository = ChatRepository(
      graphQlProvider,
      chatProvider,
      callRepository,
      userRepository,
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    SettingsRepository settingsRepository = SettingsRepository(
      mediaProvider,
      applicationSettingsProvider,
      backgroundProvider,
    );

    Get.put(
      CallService(authService, chatService, settingsRepository, callRepository),
    );

    await tester.pumpWidget(createWidgetForTesting(
      child: const UserView(UserId('9188c6b1-c2d7-4af2-a662-f68c0a00a1be')),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('user name'), findsOneWidget);
    expect(find.text('user bio'), findsOneWidget);
    expect(find.text('label_presence_present'.l10n), findsOneWidget);
    await tester.dragUntilVisible(find.byKey(const Key('UserNum')),
        find.byKey(const Key('UserColumn')), const Offset(1, 1));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('5769 2360 9862 1822 '), findsOneWidget);

    await tester.tap(find.byKey(const Key('AddToContactsButton')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    var deleteFromContacts = find.byKey(const Key('DeleteFromContactsButton'));
    expect(deleteFromContacts, findsOneWidget);
    await tester.tap(deleteFromContacts);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('AlertYesButton')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byKey(const Key('AddToContactsButton')), findsOneWidget);

    await Get.deleteAll(force: true);
  });
}

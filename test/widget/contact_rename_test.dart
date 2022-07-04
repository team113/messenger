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
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/fluent/extension.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/chat.dart';
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
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/contacts/controller.dart';
import 'package:messenger/ui/widget/context_menu/overlay.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'contact_rename_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/contact_rename_widget');

  var chatContacts = {
    'nodes': [
      {
        '__typename': 'ChatContact',
        'id': '08164fb1-ff60-49f6-8ff2-7fede51c3aed',
        'name': 'test',
        'users': [],
        'groups': [],
        'emails': [],
        'phones': [],
        'favoritePosition': null,
        'ver': '0'
      }
    ],
    'ver': '0'
  };

  var userData = {
    'id': '12',
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
    'presence': 'AWAY',
    'online': {'__typename': 'UserOnline'},
  };

  var recentChats = {
    'recentChats': {'nodes': []}
  };

  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  await sessionProvider.clear();
  var myUserProvider = Get.put(MyUserHiveProvider());
  await myUserProvider.init();
  await myUserProvider.clear();
  var galleryItemProvider = Get.put(GalleryItemHiveProvider());
  await galleryItemProvider.init();
  await galleryItemProvider.clear();
  var contactProvider = Get.put(ContactHiveProvider());
  await contactProvider.clear();
  contactProvider.init();
  var userProvider = Get.put(UserHiveProvider());
  await userProvider.init();
  await userProvider.clear();
  var chatProvider = Get.put(ChatHiveProvider());
  await chatProvider.init();
  await chatProvider.clear();
  var settingsProvider = MediaSettingsHiveProvider();
  await settingsProvider.init();
  await settingsProvider.clear();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();

  var graphQlProvider = Get.put<GraphQlProvider>(MockGraphQlProvider());
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  AuthService authService = Get.put(
    AuthService(
      Get.put<AbstractAuthRepository>(AuthRepository(graphQlProvider)),
      sessionProvider,
    ),
  );
  when(graphQlProvider.keepOnline())
      .thenAnswer((_) => Future.value(const Stream.empty()));
  await authService.init();

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      theme: Themes.light(),
      home: Builder(
        builder: (BuildContext context) {
          router.context = context;
          return Scaffold(body: ContextMenuOverlay(child: child));
        },
      ),
    );
  }

  testWidgets('ContactsTabView successfully changes contact name',
      (WidgetTester tester) async {
    when(graphQlProvider.recentChatsTopEvents(3))
        .thenAnswer((_) => Future.value(const Stream.empty()));

    final StreamController<QueryResult> contactEvents = StreamController();
    when(graphQlProvider.contactsEvents(null)).thenAnswer((_) {
      contactEvents.add(
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'chatContactsEvents': {
              '__typename': 'ChatContactsList',
              'chatContacts': chatContacts,
              'favoriteChatContacts': {'nodes': []},
            }
          },
        ),
      );

      return Future.value(contactEvents.stream);
    });

    when(graphQlProvider.myUserEvents(null)).thenAnswer(
      (_) => Future.value(Stream.fromIterable([
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'myUserEvents': {'__typename': 'MyUser', ...userData},
          },
        ),
      ])),
    );

    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer(
      (_) => Future.value(RecentChats$Query.fromJson(recentChats)),
    );

    when(graphQlProvider.incomingCalls()).thenAnswer((_) => Future.value(
        IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []})));
    when(graphQlProvider.incomingCallsTopEvents(3))
        .thenAnswer((_) => Future.value(const Stream.empty()));

    when(graphQlProvider.changeContactName(
      const ChatContactId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
      UserName('newname'),
    )).thenAnswer((_) {
      var event = {
        '__typename': 'ChatContactEventsVersioned',
        'events': [
          {
            '__typename': 'EventChatContactNameUpdated',
            'contactId': '08164fb1-ff60-49f6-8ff2-7fede51c3aed',
            'name': 'newname',
            'at': DateTime.now().toString(),
          }
        ],
        'ver': '1',
        'listVer': '1',
      };

      contactEvents.add(QueryResult.internal(
        data: {'chatContactsEvents': event},
        parserFn: (_) => null,
        source: null,
      ));

      return Future.value(UpdateChatContactName$Mutation.fromJson(
              {'updateChatContactName': event}).updateChatContactName
          as ChatContactEventsVersionedMixin?);
    });

    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    Get.put(UserService(userRepository));

    AbstractContactRepository contactRepository =
        Get.put<AbstractContactRepository>(
      ContactRepository(
        graphQlProvider,
        contactProvider,
        userRepository,
        sessionProvider,
      ),
    );
    Get.put(ContactService(contactRepository));

    AbstractMyUserRepository myUserRepository =
        MyUserRepository(graphQlProvider, myUserProvider, galleryItemProvider);
    AbstractSettingsRepository settingsRepository = Get.put(
        SettingsRepository(settingsProvider, applicationSettingsProvider));
    MyUserService myUserService =
        Get.put(MyUserService(authService, myUserRepository));

    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
        ChatRepository(graphQlProvider, chatProvider, userRepository));
    Get.put(ChatService(chatRepository, myUserService));

    CallRepository callRepository =
        CallRepository(graphQlProvider, userRepository);
    Get.put(CallService(authService, settingsRepository, callRepository));

    await tester
        .pumpWidget(createWidgetForTesting(child: const ContactsTabView()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('test'), findsOneWidget);
    await tester.longPress(find.byType(ContextMenuRegion));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text('btn_change_contact_name'.td()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.enterText(
        find.byKey(const Key('NewContactNameInput')), 'newname');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    await tester.tap(find.byKey(const Key('ContactsTab')));

    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('newname'), findsOneWidget);

    await Get.deleteAll(force: true);

    verify(graphQlProvider.changeContactName(
      const ChatContactId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
      UserName('newname'),
    ));
  });

  await myUserProvider.clear();
  await contactProvider.clear();
}

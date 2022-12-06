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
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_call_credentials.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/contact.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/contacts/controller.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'contact_rename_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/contact_rename_widget');

  var chatContact = {
    '__typename': 'ChatContact',
    'id': '08164fb1-ff60-49f6-8ff2-7fede51c3aed',
    'name': 'test',
    'users': [],
    'groups': [],
    'emails': [],
    'phones': [],
    'favoritePosition': null,
    'ver': '0'
  };

  var chatContacts = {
    'chatContacts': {
      'edges': [
        {
          'node': chatContact,
          'cursor': 'cursor',
        }
      ],
      'ver': '0'
    }
  };

  var recentChats = {
    'recentChats': {'edges': []}
  };

  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  await sessionProvider.clear();
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
  var draftProvider = Get.put(DraftHiveProvider());
  await draftProvider.init();
  await draftProvider.clear();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  var credentialsProvider = ChatCallCredentialsHiveProvider();
  await credentialsProvider.init();

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
  when(graphQlProvider.favoriteChatsEvents(null)).thenAnswer(
    (_) => Future.value(const Stream.empty()),
  );

  await authService.init();

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

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

  testWidgets('ContactsTabView successfully changes contact name',
      (WidgetTester tester) async {
    when(graphQlProvider.recentChatsTopEvents(3))
        .thenAnswer((_) => Future.value(const Stream.empty()));

    final StreamController<QueryResult> contactEvents = StreamController();

    when(graphQlProvider.chatContacts(first: 120)).thenAnswer(
      (_) => Future.value(Contacts$Query.fromJson(chatContacts).chatContacts),
    );

    when(graphQlProvider.contactsEvents(null)).thenAnswer((_) {
      return Future.value(contactEvents.stream);
    });

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

    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
      ),
    );

    CallRepository callRepository = CallRepository(
      graphQlProvider,
      userRepository,
      credentialsProvider,
    );
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        chatProvider,
        callRepository,
        draftProvider,
        userRepository,
        sessionProvider,
      ),
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    Get.put(
      CallService(authService, chatService, settingsRepository, callRepository),
    );

    await tester
        .pumpWidget(createWidgetForTesting(child: const ContactsTabView()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('test'), findsOneWidget);
    await tester.longPress(find.byType(ContextMenuRegion));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text('btn_rename'.l10n));
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

  await contactProvider.clear();
}

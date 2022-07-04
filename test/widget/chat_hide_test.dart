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
import 'package:messenger/domain/model/chat.dart';
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
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_item.dart';
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
import 'package:messenger/store/model/chat.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/chats/view.dart';
import 'package:messenger/ui/widget/context_menu/overlay.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_hide_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/chat_hide_widget');

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
    'recentChats': {
      'nodes': [
        {
          'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
          'name': 'chatname',
          'avatar': null,
          'members': {'nodes': []},
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
          'gallery': {'nodes': []},
          'unreadCount': 0,
          'totalCount': 0,
          'currentCall': null,
          'ver': '0'
        }
      ]
    }
  };

  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  await sessionProvider.clear();

  var graphQlProvider = Get.put(MockGraphQlProvider());
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  AuthService authService =
      Get.put(AuthService(AuthRepository(graphQlProvider), sessionProvider));
  await authService.init();

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

  var myUserProvider = Get.put(MyUserHiveProvider());
  await myUserProvider.init();
  await myUserProvider.clear();
  var galleryItemProvider = Get.put(GalleryItemHiveProvider());
  await galleryItemProvider.init();
  await galleryItemProvider.clear();
  var contactProvider = Get.put(ContactHiveProvider());
  await contactProvider.clear();
  await contactProvider.init();
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

  var messagesProvider = Get.put(ChatItemHiveProvider(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
  ));
  await messagesProvider.init();

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

  testWidgets('ChatsTabView successfully hides a chat',
      (WidgetTester tester) async {
    final StreamController<QueryResult> chatEvents = StreamController();
    when(graphQlProvider.chatEvents(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ChatVersion('0'),
    )).thenAnswer((_) => Future.value(chatEvents.stream));

    when(graphQlProvider.contactsEvents(null)).thenAnswer(
      (_) => Future.value(Stream.fromIterable([
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'chatContactsEvents': {
              '__typename': 'ChatContactsList',
              'chatContacts': {'nodes': [], 'ver': '0'},
              'favoriteChatContacts': {'nodes': []},
            }
          },
        )
      ])),
    );
    when(graphQlProvider.keepOnline())
        .thenAnswer((_) => Future.value(const Stream.empty()));

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

    when(graphQlProvider.hideChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).thenAnswer((_) {
      var event = {
        '__typename': 'ChatEventsVersioned',
        'events': [
          {
            '__typename': 'EventChatHidden',
            'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
            'at': DateTime.now().toString(),
          }
        ],
        'ver': '1'
      };

      chatEvents.add(QueryResult.internal(
        data: {'chatEvents': event},
        parserFn: (_) => null,
        source: null,
      ));

      return Future.value(HideChat$Mutation.fromJson({'hideChat': event})
          .hideChat as HideChat$Mutation$HideChat$ChatEventsVersioned);
    });

    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(graphQlProvider.incomingCalls()).thenAnswer((_) => Future.value(
        IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []})));
    when(graphQlProvider.incomingCallsTopEvents(3))
        .thenAnswer((_) => Future.value(const Stream.empty()));

    UserRepository userRepository =
        UserRepository(graphQlProvider, userProvider, galleryItemProvider);
    Get.put(UserService(userRepository));

    Get.put(
      ContactService(
        Get.put<AbstractContactRepository>(
          ContactRepository(
            graphQlProvider,
            contactProvider,
            userRepository,
            sessionProvider,
          ),
        ),
      ),
    );

    AbstractMyUserRepository myUserRepository = Get.put(
      MyUserRepository(
        graphQlProvider,
        myUserProvider,
        galleryItemProvider,
      ),
    );
    MyUserService myUserService =
        Get.put(MyUserService(authService, myUserRepository));

    AbstractSettingsRepository settingsRepository = Get.put(
        SettingsRepository(settingsProvider, applicationSettingsProvider));

    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(graphQlProvider, chatProvider, userRepository),
    );
    Get.put(ChatService(chatRepository, myUserService));

    Get.put(CallService(
      authService,
      settingsRepository,
      CallRepository(graphQlProvider, userRepository),
    ));

    await tester
        .pumpWidget(createWidgetForTesting(child: const ChatsTabView()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('chatname'), findsOneWidget);

    await tester.longPress(find.byType(ContextMenuRegion));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('ButtonHideChat')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('chatname'), findsNothing);

    verify(
      graphQlProvider.hideChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
    );

    await Get.deleteAll(force: true);
  });

  await myUserProvider.clear();
  await contactProvider.clear();
}

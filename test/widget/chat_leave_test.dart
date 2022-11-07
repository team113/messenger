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
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_item.dart';
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
import 'package:messenger/store/model/chat.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/chats/view.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_leave_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/chat_leave_widget');

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
          'ongoingCall': null,
          'ver': '0'
        }
      ]
    }
  };

  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  await sessionProvider.clear();
  sessionProvider.setCredentials(
    Credentials(
      Session(
        const AccessToken('token'),
        PreciseDateTime.now().add(const Duration(days: 1)),
      ),
      RememberedSession(
        const RememberToken('token'),
        PreciseDateTime.now().add(const Duration(days: 1)),
      ),
      const UserId('me'),
    ),
  );

  var graphQlProvider = Get.put(MockGraphQlProvider());
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  AuthService authService =
      Get.put(AuthService(AuthRepository(graphQlProvider), sessionProvider));
  await authService.init();

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

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
  var draftProvider = Get.put(DraftHiveProvider());
  await draftProvider.init();
  await draftProvider.clear();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  var chatItemHiveProvider = ChatItemHiveProvider(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'));
  await chatItemHiveProvider.init(userId: const UserId('me'));
  await chatItemHiveProvider.clear();

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
        theme: Themes.light(),
        home: Builder(
          builder: (BuildContext context) {
            router.context = context;
            return Scaffold(body: child);
          },
        ));
  }

  testWidgets('ChatsTabView successfully leaves a chat',
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
    when(graphQlProvider.keepOnline())
        .thenAnswer((_) => Future.value(const Stream.empty()));
    when(graphQlProvider.removeChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('me'),
    )).thenAnswer((_) {
      var event = {
        '__typename': 'ChatEventsVersioned',
        'events': [
          {
            '__typename': 'EventChatItemPosted',
            'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
            'item': {
              'node': {
                '__typename': 'ChatMemberInfo',
                'id': 'id',
                'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                'authorId': 'me',
                'at': DateTime.now().toString(),
                'ver': '0',
                'user': {
                  '__typename': 'User',
                  'id': 'me',
                  'num': '1234567890123456',
                  'login': null,
                  'name': null,
                  'bio': null,
                  'emails': {'confirmed': []},
                  'phones': {'confirmed': []},
                  'gallery': {'nodes': []},
                  'chatDirectLink': null,
                  'hasPassword': false,
                  'unreadChatsCount': 0,
                  'ver': '0',
                  'presence': 'AWAY',
                  'online': {'__typename': 'UserOnline'},
                  'mutualContactsCount': 0,
                  'isDeleted': false,
                  'isBlacklisted': {
                    'blacklisted': false,
                    'ver': '0',
                  },
                },
                'action': 'REMOVED'
              },
              'cursor': '123'
            },
          }
        ],
        'ver': '1'
      };

      chatEvents.add(QueryResult.internal(
        data: {'chatEvents': event},
        parserFn: (_) => null,
        source: null,
      ));

      return Future.value(RemoveChatMember$Mutation.fromJson(
              {'removeChatMember': event}).removeChatMember
          as RemoveChatMember$Mutation$RemoveChatMember$ChatEventsVersioned);
    });

    UserRepository userRepository = Get.put(
      UserRepository(
        graphQlProvider,
        userProvider,
        galleryItemProvider,
      ),
    );
    Get.put(UserService(userRepository));

    Get.put(ContactService(
      Get.put<AbstractContactRepository>(
        ContactRepository(
          graphQlProvider,
          contactProvider,
          userRepository,
          sessionProvider,
        ),
      ),
    ));

    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
      ),
    );

    Get.put(CallService(
      authService,
      settingsRepository,
      Get.put(CallRepository(graphQlProvider, userRepository)),
    ));

    Get.put(
      ChatService(
        Get.put<AbstractChatRepository>(
          ChatRepository(
            graphQlProvider,
            chatProvider,
            draftProvider,
            userRepository,
          ),
        ),
        authService,
      ),
    );

    await tester
        .pumpWidget(createWidgetForTesting(child: const ChatsTabView()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('chatname'), findsOneWidget);

    await tester.longPress(find.byType(ContextMenuRegion));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('ButtonLeaveChat')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('chatname'), findsNothing);

    verifyInOrder([
      graphQlProvider.removeChatMember(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const UserId('me'),
      ),
    ]);

    await Get.deleteAll(force: true);
  });

  await galleryItemProvider.clear();
  await contactProvider.clear();
  await userProvider.clear();
  await chatProvider.clear();
}

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

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/call.dart';
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
import 'package:messenger/provider/hive/chat_call_credentials.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/provider/hive/chat.dart';
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
import 'package:messenger/ui/page/home/page/chat/info/view.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_members_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/chat_members_widget');

  var chatData = {
    '__typename': 'Chat',
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
    'avatar': null,
    'name': 'null',
    'members': {'nodes': []},
    'kind': 'GROUP',
    'isHidden': false,
    'muted': null,
    'directLink': null,
    'createdAt': '2021-12-27T14:19:14.828+00:00',
    'updatedAt': '2021-12-27T14:19:14.828+00:00',
    'lastReads': [],
    'lastDelivery': '1970-01-01T00:00:00+00:00',
    'lastItem': null,
    'lastReadItem': null,
    'gallery': {'nodes': []},
    'unreadCount': 0,
    'totalCount': 0,
    'ongoingCall': null,
    'ver': '0'
  };

  var recentChats = {
    'recentChats': {
      'nodes': [chatData]
    }
  };

  var chatContacts = {
    'nodes': [
      {
        '__typename': 'ChatContact',
        'id': '09a22e75-6a54-4a17-85df-5dffa4a10a1f',
        'name': 'text2',
        'users': [
          {
            'id': '08164fb1-ff60-49f6-8ff2-7fede51c3ae3',
            'num': '1234567890123456',
            'name': 'text2',
            'bio': 'text2',
            'avatar': null,
            'callCover': null,
            'gallery': {'nodes': []},
            'mutualContactsCount': 1,
            'online': null,
            'presence': 'text2',
            'status': 'text2',
            'isDeleted': false,
            'dialog': null,
            'isBlacklisted': {'blacklisted': false, 'ver': '0'},
            'ver': '0',
          }
        ],
        'groups': [],
        'emails': [],
        'phones': [],
        'favoritePosition': null,
        'ver': '0'
      }
    ],
    'ver': '0',
  };

  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  await sessionProvider.clear();

  var graphQlProvider = Get.put(MockGraphQlProvider());
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(graphQlProvider.keepOnline())
      .thenAnswer((_) => Future.value(const Stream.empty()));
  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  when(graphQlProvider.favoriteChatsEvents(null)).thenAnswer(
    (_) => Future.value(const Stream.empty()),
  );

  var galleryItemProvider = Get.put(GalleryItemHiveProvider());
  await galleryItemProvider.init();
  await galleryItemProvider.clear();
  await Future.delayed(Duration.zero);
  var contactProvider = Get.put(ContactHiveProvider());
  await contactProvider.init();
  await contactProvider.clear();
  var userProvider = Get.put(UserHiveProvider());
  await userProvider.init();
  await userProvider.clear();
  var chatProvider = Get.put(ChatHiveProvider());
  await chatProvider.init();
  await chatProvider.clear();
  var mediaSettingsProvider = MediaSettingsHiveProvider();
  await mediaSettingsProvider.init();
  await mediaSettingsProvider.clear();
  var draftProvider = Get.put(DraftHiveProvider());
  await draftProvider.init();
  await draftProvider.clear();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  var chatItemHiveProvider = ChatItemHiveProvider(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'));
  await chatItemHiveProvider.init(userId: const UserId('id'));
  await chatItemHiveProvider.clear();
  var credentialsProvider = ChatCallCredentialsHiveProvider();
  await credentialsProvider.init();

  Widget createWidgetForTesting({required Widget child}) => MaterialApp(
        theme: Themes.light(),
        home: Scaffold(body: child),
      );

  testWidgets('ChatInfoView successfully adds and removes chat members',
      (WidgetTester tester) async {
    final StreamController<QueryResult> chatEvents = StreamController();
    when(graphQlProvider.chatEvents(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ChatVersion('0'),
    )).thenAnswer((_) => Future.value(chatEvents.stream));

    when(graphQlProvider
            .getChat(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer((_) => Future.value(GetChat$Query.fromJson(chatData)));

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

    when(graphQlProvider.addChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('08164fb1-ff60-49f6-8ff2-7fede51c3ae3'),
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
                'authorId': '12',
                'at': DateTime.now().toString(),
                'ver': '0',
                'user': {
                  '__typename': 'User',
                  'id': '08164fb1-ff60-49f6-8ff2-7fede51c3ae3',
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
                'action': 'ADDED'
              },
              'cursor': '123'
            },
          }
        ],
        'ver': '1'
      };

      chatEvents.add(QueryResult.internal(
        data: {'chatEvents': event},
        source: QueryResultSource.network,
        parserFn: (_) => null,
      ));

      return Future.value(
          AddChatMember$Mutation.fromJson({'addChatMember': event})
                  .addChatMember
              as AddChatMember$Mutation$AddChatMember$ChatEventsVersioned);
    });

    when(graphQlProvider.removeChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('08164fb1-ff60-49f6-8ff2-7fede51c3ae3'),
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
                'authorId': '12',
                'at': DateTime.now().toString(),
                'ver': '0',
                'user': {
                  '__typename': 'User',
                  'id': '08164fb1-ff60-49f6-8ff2-7fede51c3ae3',
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
        'ver': '2'
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

    when(graphQlProvider.contactsEvents(null)).thenAnswer(
      (_) => Future.value(Stream.fromIterable([
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
        )
      ])),
    );

    AuthService authService =
        Get.put(AuthService(AuthRepository(graphQlProvider), sessionProvider));
    await authService.init();

    router = RouterState(authService);
    router.provider = MockPlatformRouteInformationProvider();

    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        mediaSettingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
      ),
    );
    UserRepository userRepository =
        UserRepository(graphQlProvider, userProvider, galleryItemProvider);
    AbstractCallRepository callRepository = CallRepository(
      graphQlProvider,
      userRepository,
      credentialsProvider,
      settingsRepository,
      me: const UserId('me'),
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
    AbstractContactRepository contactRepository = ContactRepository(
      graphQlProvider,
      contactProvider,
      userRepository,
      sessionProvider,
    );

    Get.put(ContactService(contactRepository));
    ChatService chatService = Get.put(ChatService(chatRepository, authService));
    Get.put(CallService(authService, chatService, callRepository));
    Get.put(UserService(userRepository));

    await tester.pumpWidget(createWidgetForTesting(
      child: const ChatInfoView(ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')),
    ));

    await tester.pumpAndSettle(const Duration(seconds: 20));

    expect(find.byKey(const Key('DeleteChatMember')), findsNothing);

    await tester.tap(find.byKey(const Key('AddMemberButton')));
    await tester.pumpAndSettle(const Duration(seconds: 20));

    expect(find.text('text2'), findsOneWidget);
    await tester.tap(find.text('text2'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('AddChatMembersButton')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byKey(const Key('DeleteChatMember')), findsOneWidget);

    await tester.tap(find.byKey(const Key('DeleteChatMember')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('DeleteChatMember')), findsNothing);

    verify(graphQlProvider.addChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('08164fb1-ff60-49f6-8ff2-7fede51c3ae3'),
    ));

    verify(graphQlProvider.removeChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('08164fb1-ff60-49f6-8ff2-7fede51c3ae3'),
    ));

    await Get.deleteAll(force: true);
  });
}

// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_call_credentials.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_read_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<GraphQlProvider>(onMissingStub: OnMissingStub.returnDefault)
])
void main() async {
  setUp(Get.reset);

  Hive.init('./test/.temp_hive/chat_read_unit');

  final graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  var galleryItemProvider = GalleryItemHiveProvider();
  await galleryItemProvider.init();
  var chatProvider = ChatHiveProvider();
  await chatProvider.init();
  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  var credentialsProvider = ChatCallCredentialsHiveProvider();
  await credentialsProvider.init();
  var draftProvider = DraftHiveProvider();
  await draftProvider.init();
  var mediaSettingsProvider = MediaSettingsHiveProvider();
  await mediaSettingsProvider.init();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();

  var chatData = {
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
    'name': null,
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
  };

  var recentChats = {
    'recentChats': {
      'nodes': [chatData]
    }
  };

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    any,
  )).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.favoriteChatsEvents(any))
      .thenAnswer((_) => const Stream.empty());

  AuthService authService = Get.put(
    AuthService(
      Get.put<AbstractAuthRepository>(AuthRepository(graphQlProvider)),
      sessionProvider,
    ),
  );
  await authService.init();

  test('ChatService successfully reads messages', () async {
    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(graphQlProvider.getChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).thenAnswer(
        (_) => Future.value(GetChat$Query.fromJson({'chat': chatData})));

    when(graphQlProvider.readChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const ChatItemId(''),
    )).thenAnswer((_) =>
        Future.value(ReadChat$Mutation$ReadChat$ChatEventsVersioned.fromJson(
          {
            '__typename': 'ChatEventsVersioned',
            'events': [
              {
                '__typename': 'EventChatRead',
                'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                'byUser': {
                  '__typename': 'User',
                  'id': '0d72d245-8425-467a-9ebd-082d4f47850a',
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
                'at': DateTime.now().toString(),
              }
            ],
            'ver': '0'
          },
        )));

    Get.put(chatProvider);

    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        mediaSettingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
      ),
    );
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    CallRepository callRepository = Get.put(
      CallRepository(
        graphQlProvider,
        userRepository,
        credentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
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

    await chatService.readChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const ChatItemId(''),
    );
    await Future.delayed(2.seconds);

    verify(graphQlProvider.readChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const ChatItemId(''),
    ));
  });
}

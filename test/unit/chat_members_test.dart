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
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/call_rect.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_call_credentials.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/monolog.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_members_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  setUp(Get.reset);

  Hive.init('./test/.temp_hive/chat_members_unit');

  final graphQlProvider = Get.put(MockGraphQlProvider());
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  var chatProvider = Get.put(ChatHiveProvider());
  await chatProvider.init();
  var galleryItemProvider = Get.put(GalleryItemHiveProvider());
  await galleryItemProvider.init();
  var chatHiveProvider = Get.put(ChatHiveProvider());
  await chatHiveProvider.init();
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
  var callRectProvider = CallRectHiveProvider();
  await callRectProvider.init();
  var monologProvider = MonologHiveProvider();
  await monologProvider.init();

  var recentChats = {
    'recentChats': {'nodes': []}
  };

  var chatData = {
    'num': '1234567890123456',
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
    'avatar': null,
  };

  var addChatMemberData = {
    'addChatMember': {
      '__typename': 'ChatEventsVersioned',
      'events': [
        {
          '__typename': 'EventChatItemPosted',
          'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
          'item': {
            'node': {
              '__typename': 'ChatInfo',
              'id': 'id',
              'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
              'authorId': 'me',
              'at': DateTime.now().toString(),
              'ver': '0',
              'author': {
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
              'action': {
                '__typename': 'ChatInfoActionMemberAdded',
                'user': {
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
              },
            },
            'cursor': '123'
          },
        }
      ],
      'ver': '0'
    }
  };

  var removeChatMemberData = {
    'removeChatMember': {
      '__typename': 'ChatEventsVersioned',
      'events': [
        {
          '__typename': 'EventChatItemPosted',
          'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
          'item': {
            'node': {
              '__typename': 'ChatInfo',
              'id': 'id',
              'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
              'authorId': 'me',
              'at': DateTime.now().toString(),
              'ver': '0',
              'author': {
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
              'action': {
                '__typename': 'ChatInfoActionMemberRemoved',
                'user': {
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
              },
            },
            'cursor': '123'
          },
        }
      ],
      'ver': '0'
    }
  };

  when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.favoriteChatsEvents(any))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  Future<ChatService> init(GraphQlProvider graphQlProvider) async {
    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        mediaSettingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );

    Get.put(graphQlProvider);
    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    await authService.init();

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
        monologProvider,
        me: const UserId('me'),
      ),
    );
    return Get.put(ChatService(chatRepository, authService));
  }

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

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.chatEvents(
    const ChatId('fc95f181-ae23-41b7-b246-5d6bdbe577a1'),
    any,
  )).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.chatEvents(
    const ChatId('c36343e2-e8af-4d55-9982-38ba68d2b785'),
    any,
  )).thenAnswer((_) => const Stream.empty());

  ChatService chatService = await init(graphQlProvider);

  test('ChatService successfully adds a participant to chat', () async {
    when(graphQlProvider.addChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
    )).thenAnswer((_) => Future.value(
        AddChatMember$Mutation.fromJson(addChatMemberData).addChatMember
            as AddChatMember$Mutation$AddChatMember$ChatEventsVersioned));

    await chatService.addChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
    );

    verify(graphQlProvider.addChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
    ));
  });

  test('ChatService throws AddChatMemberException when adding new chat member',
      () async {
    when(graphQlProvider.addChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
    )).thenThrow(
        const AddChatMemberException(AddChatMemberErrorCode.blacklisted));

    expect(
      () async => await chatService.addChatMember(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
      ),
      throwsA(isA<AddChatMemberException>()),
    );

    verify(graphQlProvider.addChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
    ));
  });

  test('ChatService successfully removes participant from the chat', () async {
    when(graphQlProvider.removeChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
    )).thenAnswer((_) => Future.value(RemoveChatMember$Mutation.fromJson(
          removeChatMemberData,
        ).removeChatMember
            as RemoveChatMember$Mutation$RemoveChatMember$ChatEventsVersioned));

    await chatService.removeChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
    );

    verify(graphQlProvider.removeChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
    ));
  });

  test('ChatService throws RemoveChatMemberException when removing chat member',
      () async {
    when(graphQlProvider.removeChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
    )).thenThrow(
        const RemoveChatMemberException(RemoveChatMemberErrorCode.unknownChat));

    expect(
      () async => await chatService.removeChatMember(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
      ),
      throwsA(isA<RemoveChatMemberException>()),
    );

    verify(graphQlProvider.removeChatMember(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const UserId('0d72d245-8425-467a-9ebd-082d4f47850a'),
    ));
  });
}

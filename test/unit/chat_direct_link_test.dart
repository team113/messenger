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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/blacklist.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_call_credentials.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/model/chat.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_direct_link_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  setUp(Get.reset);

  Hive.init('./test/.temp_hive/chat_direct_link_unit');

  final graphQlProvider = Get.put(MockGraphQlProvider());

  var chatProvider = Get.put(ChatHiveProvider());
  await chatProvider.init();
  var galleryItemProvider = GalleryItemHiveProvider();
  await galleryItemProvider.init();
  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  var myUserProvider = Get.put(MyUserHiveProvider());
  await myUserProvider.init();
  await myUserProvider.clear();
  var draftProvider = DraftHiveProvider();
  await draftProvider.init();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  var credentialsProvider = ChatCallCredentialsHiveProvider();
  await credentialsProvider.init();
  var mediaSettingsProvider = MediaSettingsHiveProvider();
  await mediaSettingsProvider.init();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  var blacklistedUsersProvider = BlacklistHiveProvider();
  await blacklistedUsersProvider.init();

  var recentChats = {
    'recentChats': {
      'nodes': [
        {
          'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
          'name': 'null',
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

  var myUserData = {
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
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
  };

  var blacklist = {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    }
  };

  when(graphQlProvider.myUserEvents(null)).thenAnswer(
    (_) => Future.value(Stream.fromIterable([
      QueryResult.internal(
        parserFn: (_) => null,
        source: null,
        data: {
          'myUserEvents': {'__typename': 'MyUser', ...myUserData},
        },
      ),
    ])),
  );

  when(graphQlProvider.disconnect()).thenAnswer((_) => Future.value);
  when(graphQlProvider.keepOnline())
      .thenAnswer((_) => Future.value(const Stream.empty()));

  when(graphQlProvider.favoriteChatsEvents(null)).thenAnswer(
    (_) => Future.value(const Stream.empty()),
  );

  when(graphQlProvider.getBlacklist(
    first: 120,
    after: null,
    last: null,
    before: null,
  )).thenAnswer(
    (_) => Future.value(GetBlacklist$Query$Blacklist.fromJson(blacklist)),
  );

  AuthService authService = Get.put(
    AuthService(
      Get.put<AbstractAuthRepository>(AuthRepository(graphQlProvider)),
      sessionProvider,
    ),
  );
  await authService.init();

  UserRepository userRepository = Get.put(
      UserRepository(graphQlProvider, userProvider, galleryItemProvider));
  AbstractMyUserRepository myUserRepository = MyUserRepository(
    graphQlProvider,
    myUserProvider,
    blacklistedUsersProvider,
    galleryItemProvider,
    userRepository,
  );
  MyUserService myUserService =
      Get.put(MyUserService(authService, myUserRepository));

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    ChatVersion('0'),
  )).thenAnswer((_) => Future.value(const Stream.empty()));

  when(graphQlProvider.recentChats(
    first: 120,
    after: null,
    last: null,
    before: null,
  )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

  test('ChatService and UserService successfully create ChatDirectLink',
      () async {
    when(graphQlProvider.createChatDirectLink(
      ChatDirectLinkSlug('link'),
      groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).thenAnswer(
      (_) => Future.value(CreateChatDirectLink$Mutation.fromJson({
        'createChatDirectLink': {
          '__typename': 'ChatEventsVersioned',
          'events': [
            {
              '__typename': 'EventChatDirectLinkUpdated',
              'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
              'directLink': {
                'slug': 'link',
                'usageCount': 0,
              },
            }
          ],
          'ver': '0',
        }
      }).createChatDirectLink as ChatEventsVersionedMixin?),
    );

    when(graphQlProvider.createUserDirectLink(ChatDirectLinkSlug('link')))
        .thenAnswer(
      (_) => Future.value(CreateUserDirectLink$Mutation.fromJson({
        'createChatDirectLink': {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserDirectLinkUpdated',
              'userId': '0d72d245-8425-467a-9ebd-082d4f47850b',
              'directLink': {
                'slug': 'link',
                'usageCount': 0,
              },
            }
          ],
          'myUser': myUserData,
          'ver': '0',
        }
      }).createChatDirectLink as MyUserEventsVersionedMixin?),
    );

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

    await chatService.createChatDirectLink(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ChatDirectLinkSlug('link'),
    );

    await myUserService.createChatDirectLink(ChatDirectLinkSlug('link'));

    verifyInOrder([
      graphQlProvider.createChatDirectLink(
        ChatDirectLinkSlug('link'),
        groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
      graphQlProvider.createUserDirectLink(ChatDirectLinkSlug('link')),
    ]);
  });

  test('ChatService successfully deletes ChatDirectLink', () async {
    when(graphQlProvider.deleteChatDirectLink(
      groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).thenAnswer(
      (_) => Future.value(),
    );

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

    await chatService.deleteChatDirectLink(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    );

    verify(
      graphQlProvider.deleteChatDirectLink(
        groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
    );
  });

  test('ChatService successfully uses ChatDirectLink', () async {
    when(graphQlProvider.useChatDirectLink(
      ChatDirectLinkSlug('link'),
    )).thenAnswer(
      (_) => Future.value(UseChatDirectLink$Mutation.fromJson({
        'useChatDirectLink': {
          '__typename': 'UseChatDirectLinkOk',
          'chat': {
            'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
            'name': 'null',
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
          },
          'event': null
        }
      }).useChatDirectLink
          as UseChatDirectLink$Mutation$UseChatDirectLink$UseChatDirectLinkOk),
    );

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
    Get.put(ChatService(chatRepository, authService));

    authService.useChatDirectLink(ChatDirectLinkSlug('link'));

    verify(
      graphQlProvider.useChatDirectLink(ChatDirectLinkSlug('link')),
    );
  });

  test(
      'ChatService and UserService throw CreateChatDirectLinkException on ChatDirectLink creation',
      () async {
    when(graphQlProvider.createChatDirectLink(
      ChatDirectLinkSlug('link'),
      groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).thenThrow(const CreateChatDirectLinkException(
        CreateChatDirectLinkErrorCode.unknownChat));

    when(graphQlProvider.createUserDirectLink(ChatDirectLinkSlug('link')))
        .thenThrow(const CreateChatDirectLinkException(
            CreateChatDirectLinkErrorCode.unknownChat));

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

    expect(
      () async => await chatService.createChatDirectLink(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ChatDirectLinkSlug('link'),
      ),
      throwsA(isA<CreateChatDirectLinkException>()),
    );

    expect(
      () async =>
          await myUserService.createChatDirectLink(ChatDirectLinkSlug('link')),
      throwsA(isA<CreateChatDirectLinkException>()),
    );

    verifyInOrder([
      graphQlProvider.createChatDirectLink(
        ChatDirectLinkSlug('link'),
        groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
      graphQlProvider.createUserDirectLink(ChatDirectLinkSlug('link')),
    ]);
  });

  test(
      'ChatService throws DeleteChatDirectLinkException on ChatDirectLink deletion',
      () async {
    when(graphQlProvider.deleteChatDirectLink(
      groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).thenThrow(const DeleteChatDirectLinkException(
        DeleteChatDirectLinkErrorCode.unknownChat));

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

    expect(
      () async => await chatService.deleteChatDirectLink(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
      throwsA(isA<DeleteChatDirectLinkException>()),
    );

    verify(
      graphQlProvider.deleteChatDirectLink(
        groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
    );
  });

  test(
      'ChatService throws DeleteChatDirectLinkException on ChatDirectLink deletion',
      () async {
    when(graphQlProvider.useChatDirectLink(
      ChatDirectLinkSlug('link'),
    )).thenThrow(const UseChatDirectLinkException(
        UseChatDirectLinkErrorCode.unknownDirectLink));

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
    Get.put(ChatService(chatRepository, authService));

    expect(
      () => authService.useChatDirectLink(
        ChatDirectLinkSlug('link'),
      ),
      throwsA(isA<UseChatDirectLinkException>()),
    );

    verify(
      graphQlProvider.useChatDirectLink(
        ChatDirectLinkSlug('link'),
      ),
    );
  });
}

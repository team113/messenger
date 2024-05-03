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
import 'package:messenger/provider/hive/account.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/blocklist.dart';
import 'package:messenger/provider/hive/blocklist_sorting.dart';
import 'package:messenger/provider/hive/call_credentials.dart';
import 'package:messenger/provider/hive/call_rect.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_credentials.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/favorite_chat.dart';
import 'package:messenger/provider/hive/session_data.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/monolog.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/recent_chat.dart';
import 'package:messenger/provider/hive/credentials.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/blocklist.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
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
  var credentialsProvider = Get.put(CredentialsHiveProvider());
  await credentialsProvider.init();
  var myUserProvider = Get.put(MyUserHiveProvider());
  await myUserProvider.init();
  await myUserProvider.clear();
  var draftProvider = DraftHiveProvider();
  await draftProvider.init();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  final callCredentialsProvider = CallCredentialsHiveProvider();
  await callCredentialsProvider.init();
  final chatCredentialsProvider = ChatCredentialsHiveProvider();
  await chatCredentialsProvider.init();
  var mediaSettingsProvider = MediaSettingsHiveProvider();
  await mediaSettingsProvider.init();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
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
  var blocklistSortingProvider = BlocklistSortingHiveProvider();
  await blocklistSortingProvider.init();
  final accountProvider = AccountHiveProvider();
  await accountProvider.init();

  var chatData = {
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
    'name': 'null',
    'members': {'nodes': [], 'totalCount': 0},
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
    'unreadCount': 0,
    'totalCount': 0,
    'ongoingCall': null,
    'ver': '0',
  };

  var recentChats = {
    'recentChats': {
      'edges': [
        {
          'node': chatData,
          'cursor': 'cursor',
        }
      ],
      'pageInfo': {
        'endCursor': 'endCursor',
        'hasNextPage': false,
        'startCursor': 'startCursor',
        'hasPreviousPage': false,
      }
    }
  };

  var favoriteChats = {
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

  var myUserData = {
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
    'num': '1234567890123456',
    'login': null,
    'name': null,
    'emails': {'confirmed': []},
    'phones': {'confirmed': []},
    'chatDirectLink': null,
    'hasPassword': false,
    'unreadChatsCount': 0,
    'ver': '0',
    'presence': 'AWAY',
    'online': {'__typename': 'UserOnline'},
    'blocklist': {'totalCount': 0},
  };

  var blocklist = {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    }
  };

  when(graphQlProvider.myUserEvents(any)).thenAnswer(
    (_) => Stream.fromIterable([
      QueryResult.internal(
        parserFn: (_) => null,
        source: null,
        data: {
          'myUserEvents': {'__typename': 'MyUser', ...myUserData},
        },
      ),
    ]),
  );

  when(graphQlProvider.disconnect()).thenAnswer((_) => Future.value);
  when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.favoriteChatsEvents(any))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.getBlocklist(
    first: anyNamed('first'),
    after: null,
    last: null,
    before: null,
  )).thenAnswer(
    (_) => Future.value(GetBlocklist$Query$Blocklist.fromJson(blocklist)),
  );

  AuthService authService = Get.put(
    AuthService(
      Get.put<AbstractAuthRepository>(AuthRepository(
        graphQlProvider,
        myUserProvider,
        credentialsProvider,
      )),
      credentialsProvider,
      accountProvider,
    ),
  );
  authService.init();

  UserRepository userRepository =
      Get.put(UserRepository(graphQlProvider, userProvider));

  BlocklistRepository blocklistRepository = Get.put(
    BlocklistRepository(
      graphQlProvider,
      blockedUsersProvider,
      blocklistSortingProvider,
      userRepository,
      sessionProvider,
    ),
  );

  AbstractMyUserRepository myUserRepository = MyUserRepository(
    graphQlProvider,
    myUserProvider,
    blocklistRepository,
    userRepository,
    accountProvider,
  );
  MyUserService myUserService =
      Get.put(MyUserService(authService, myUserRepository));

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    any,
    any,
  )).thenAnswer((_) => const Stream.empty());

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

  when(graphQlProvider.getUser(any))
      .thenAnswer((_) => Future.value(GetUser$Query.fromJson({'user': null})));
  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

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
        },
      }).createChatDirectLink as MyUserEventsVersionedMixin?),
    );

    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        mediaSettingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );

    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));
    final CallRepository callRepository = Get.put(
      CallRepository(
        graphQlProvider,
        userRepository,
        callCredentialsProvider,
        chatCredentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
    );
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
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
        callRectProvider,
      ),
    );

    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));
    final CallRepository callRepository = Get.put(
      CallRepository(
        graphQlProvider,
        userRepository,
        callCredentialsProvider,
        chatCredentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
    );
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
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
            'members': {'nodes': [], 'totalCount': 0},
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
        callRectProvider,
      ),
    );

    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));
    final CallRepository callRepository = Get.put(
      CallRepository(
        graphQlProvider,
        userRepository,
        callCredentialsProvider,
        chatCredentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
    );
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
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
        callRectProvider,
      ),
    );

    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));
    final CallRepository callRepository = Get.put(
      CallRepository(
        graphQlProvider,
        userRepository,
        callCredentialsProvider,
        chatCredentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
    );
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
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
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    await expectLater(
      () async => await chatService.createChatDirectLink(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ChatDirectLinkSlug('link'),
      ),
      throwsA(isA<CreateChatDirectLinkException>()),
    );

    await expectLater(
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
        callRectProvider,
      ),
    );

    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));
    final CallRepository callRepository = Get.put(
      CallRepository(
        graphQlProvider,
        userRepository,
        callCredentialsProvider,
        chatCredentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
    );
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
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
        callRectProvider,
      ),
    );

    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));
    final CallRepository callRepository = Get.put(
      CallRepository(
        graphQlProvider,
        userRepository,
        callCredentialsProvider,
        chatCredentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
    );
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
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

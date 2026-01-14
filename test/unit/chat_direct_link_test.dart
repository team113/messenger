// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:graphql/client.dart';
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
import 'package:messenger/provider/drift/account.dart';
import 'package:messenger/provider/drift/background.dart';
import 'package:messenger/provider/drift/blocklist.dart';
import 'package:messenger/provider/drift/call_credentials.dart';
import 'package:messenger/provider/drift/call_rect.dart';
import 'package:messenger/provider/drift/chat.dart';
import 'package:messenger/provider/drift/chat_credentials.dart';
import 'package:messenger/provider/drift/chat_item.dart';
import 'package:messenger/provider/drift/chat_member.dart';
import 'package:messenger/provider/drift/credentials.dart';
import 'package:messenger/provider/drift/draft.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/locks.dart';
import 'package:messenger/provider/drift/monolog.dart';
import 'package:messenger/provider/drift/my_user.dart';
import 'package:messenger/provider/drift/secret.dart';
import 'package:messenger/provider/drift/settings.dart';
import 'package:messenger/provider/drift/slugs.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/drift/version.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';
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

@GenerateNiceMocks([MockSpec<GraphQlProvider>()])
void main() async {
  setUp(() async {
    final graphQlProvider = MockGraphQlProvider();

    when(graphQlProvider.myUserEvents(any)).thenAnswer(
      (_) async => Stream.fromIterable([
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
    when(
      graphQlProvider.onStart,
    ).thenReturn(InternalFinalCallback(callback: () {}));
    when(
      graphQlProvider.onDelete,
    ).thenReturn(InternalFinalCallback(callback: () {}));
    when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

    Get.put<GraphQlProvider>(graphQlProvider);

    when(
      graphQlProvider.favoriteChatsEvents(any),
    ).thenAnswer((_) => const Stream.empty());

    when(
      graphQlProvider.getBlocklist(
        first: anyNamed('first'),
        after: null,
        last: null,
        before: null,
      ),
    ).thenAnswer(
      (_) => Future.value(GetBlocklist$Query$Blocklist.fromJson(blocklist)),
    );

    when(
      graphQlProvider.recentChatsTopEvents(3),
    ).thenAnswer((_) => const Stream.empty());
    when(
      graphQlProvider.recentChatsTopEvents(3, archived: true),
    ).thenAnswer((_) => const Stream.empty());
    when(
      graphQlProvider.incomingCallsTopEvents(3),
    ).thenAnswer((_) => const Stream.empty());
    when(
      graphQlProvider.sessionsEvents(any),
    ).thenAnswer((_) => const Stream.empty());
    when(
      graphQlProvider.blocklistEvents(any),
    ).thenAnswer((_) => const Stream.empty());

    when(
      graphQlProvider.chatEvents(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        any,
        any,
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      graphQlProvider.recentChats(
        first: anyNamed('first'),
        after: null,
        last: null,
        before: null,
        noFavorite: anyNamed('noFavorite'),
        archived: anyNamed('archived'),
        withOngoingCalls: anyNamed('withOngoingCalls'),
      ),
    ).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(
      graphQlProvider.favoriteChats(
        first: anyNamed('first'),
        after: null,
        last: null,
        before: null,
      ),
    ).thenAnswer(
      (_) => Future.value(FavoriteChats$Query.fromJson(favoriteChats)),
    );

    when(graphQlProvider.getUser(any)).thenAnswer(
      (_) => Future.value(GetUser$Query.fromJson({'user': null}).user),
    );
    when(graphQlProvider.getMonolog()).thenAnswer(
      (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
    );

    final common = Get.put(CommonDriftProvider.memory());
    final scoped = Get.put(ScopedDriftProvider.memory());

    final credentialsProvider = Get.put(CredentialsDriftProvider(common));
    final accountProvider = Get.put(AccountDriftProvider(common));
    final settingsProvider = Get.put(SettingsDriftProvider(common));
    final myUserProvider = Get.put(MyUserDriftProvider(common));
    final userProvider = Get.put(UserDriftProvider(common, scoped));
    final chatItemProvider = Get.put(ChatItemDriftProvider(common, scoped));
    final chatMemberProvider = Get.put(ChatMemberDriftProvider(common, scoped));
    final chatProvider = Get.put(ChatDriftProvider(common, scoped));
    final backgroundProvider = Get.put(BackgroundDriftProvider(common));
    final blocklistProvider = Get.put(BlocklistDriftProvider(common, scoped));
    final callCredentialsProvider = Get.put(
      CallCredentialsDriftProvider(common, scoped),
    );
    final chatCredentialsProvider = Get.put(
      ChatCredentialsDriftProvider(common, scoped),
    );
    final callRectProvider = Get.put(CallRectDriftProvider(common, scoped));
    final draftProvider = Get.put(DraftDriftProvider(common, scoped));
    final monologProvider = Get.put(MonologDriftProvider(common, scoped));
    final versionProvider = Get.put(VersionDriftProvider(common));
    final locksProvider = Get.put(LockDriftProvider(common));
    final secretsProvider = Get.put(RefreshSecretDriftProvider(common));
    final slugProvider = Get.put(SlugDriftProvider(common));

    final AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(
          AuthRepository(
            graphQlProvider,
            myUserProvider,
            Get.find(),
            slugProvider,
          ),
        ),
        credentialsProvider,
        accountProvider,
        locksProvider,
        secretsProvider,
      ),
    );
    router = RouterState(authService);
    await authService.init();

    final UserRepository userRepository = Get.put(
      UserRepository(graphQlProvider, userProvider, me: const UserId('me')),
    );

    final BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
        graphQlProvider,
        blocklistProvider,
        userRepository,
        versionProvider,
        me: const UserId('me'),
      ),
    );

    final AbstractMyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      blocklistRepository,
      userRepository,
      Get.find(),
      me: const UserId('me'),
    );

    Get.put(MyUserService(authService, myUserRepository));

    final AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        backgroundProvider,
        callRectProvider,
        me: const UserId('me'),
      ),
    );

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
    final AbstractChatRepository chatRepository =
        Get.put<AbstractChatRepository>(
          ChatRepository(
            graphQlProvider,
            chatProvider,
            chatItemProvider,
            chatMemberProvider,
            callRepository,
            draftProvider,
            userRepository,
            Get.find(),
            monologProvider,
            slugProvider,
            me: const UserId('me'),
          ),
        );

    Get.put(ChatService(chatRepository, Get.find()));
  });

  test(
    'ChatService and UserService successfully create ChatDirectLink',
    () async {
      final GraphQlProvider graphQlProvider = Get.find();
      final ChatService chatService = Get.find();
      final MyUserService myUserService = Get.find();

      when(
        graphQlProvider.createChatDirectLink(
          ChatDirectLinkSlug('link'),
          groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ),
      ).thenAnswer(
        (_) => Future.value(
          CreateChatDirectLink$Mutation.fromJson({
                'createChatDirectLink': {
                  '__typename': 'ChatEventsVersioned',
                  'events': [
                    {
                      '__typename': 'EventChatDirectLinkUpdated',
                      'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                      'directLink': {
                        'slug': 'link',
                        'usageCount': 0,
                        'createdAt': DateTime.now().toString(),
                      },
                    },
                  ],
                  'ver': '0',
                },
              }).createChatDirectLink
              as ChatEventsVersionedMixin?,
        ),
      );

      when(
        graphQlProvider.createUserDirectLink(ChatDirectLinkSlug('link')),
      ).thenAnswer(
        (_) => Future.value(
          CreateUserDirectLink$Mutation.fromJson({
                'createChatDirectLink': {
                  '__typename': 'MyUserEventsVersioned',
                  'events': [
                    {
                      '__typename': 'EventUserDirectLinkUpdated',
                      'userId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                      'directLink': {
                        'slug': 'link',
                        'usageCount': 0,
                        'createdAt': DateTime.now().toString(),
                      },
                    },
                  ],
                  'myUser': myUserData,
                  'ver': '0',
                },
              }).createChatDirectLink
              as MyUserEventsVersionedMixin?,
        ),
      );

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
    },
  );

  test('ChatService successfully deletes ChatDirectLink', () async {
    final GraphQlProvider graphQlProvider = Get.find();
    final ChatService chatService = Get.find();

    when(
      graphQlProvider.deleteChatDirectLink(
        groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
    ).thenAnswer((_) => Future.value());

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
    final GraphQlProvider graphQlProvider = Get.find();
    final ChatService chatService = Get.find();

    when(
      graphQlProvider.useChatDirectLink(ChatDirectLinkSlug('link')),
    ).thenAnswer(
      (_) => Future.value(
        UseChatDirectLink$Mutation.fromJson({
              'useChatDirectLink': {
                '__typename': 'UseChatDirectLinkOk',
                'chat': {
                  'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
                  'name': 'null',
                  'members': {'nodes': [], 'totalCount': 0},
                  'kind': 'GROUP',
                  'isHidden': false,
                  'isArchived': false,
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
                },
                'event': null,
              },
            }).useChatDirectLink
            as UseChatDirectLink$Mutation$UseChatDirectLink$UseChatDirectLinkOk,
      ),
    );

    await chatService.useChatDirectLink(ChatDirectLinkSlug('link'));

    verify(graphQlProvider.useChatDirectLink(ChatDirectLinkSlug('link')));
  });

  test(
    'ChatService and UserService does not throw CreateChatDirectLinkException on ChatDirectLink creation',
    () async {
      final GraphQlProvider graphQlProvider = Get.find();
      final ChatService chatService = Get.find();
      final MyUserService myUserService = Get.find();

      when(
        graphQlProvider.createChatDirectLink(
          ChatDirectLinkSlug('link'),
          groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ),
      ).thenThrow(
        const CreateChatDirectLinkException(
          CreateChatDirectLinkErrorCode.unknownChat,
        ),
      );

      when(
        graphQlProvider.createUserDirectLink(ChatDirectLinkSlug('link')),
      ).thenThrow(
        const CreateChatDirectLinkException(
          CreateChatDirectLinkErrorCode.unknownChat,
        ),
      );

      await chatService.createChatDirectLink(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ChatDirectLinkSlug('link'),
      );

      await expectLater(
        () async => await myUserService.createChatDirectLink(
          ChatDirectLinkSlug('link'),
        ),
        throwsA(isA<CreateChatDirectLinkException>()),
      );

      verifyInOrder([
        graphQlProvider.createChatDirectLink(
          ChatDirectLinkSlug('link'),
          groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ),
        graphQlProvider.createUserDirectLink(ChatDirectLinkSlug('link')),
      ]);
    },
  );

  test(
    'ChatService does not throw DeleteChatDirectLinkException on ChatDirectLink deletion',
    () async {
      final GraphQlProvider graphQlProvider = Get.find();
      final ChatService chatService = Get.find();

      when(
        graphQlProvider.deleteChatDirectLink(
          groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ),
      ).thenThrow(
        const DeleteChatDirectLinkException(
          DeleteChatDirectLinkErrorCode.unknownChat,
        ),
      );

      await chatService.deleteChatDirectLink(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      );

      verify(
        graphQlProvider.deleteChatDirectLink(
          groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ),
      );
    },
  );

  test(
    'ChatService throws DeleteChatDirectLinkException on ChatDirectLink deletion',
    () async {
      final GraphQlProvider graphQlProvider = Get.find();
      final ChatService chatService = Get.find();

      when(
        graphQlProvider.useChatDirectLink(ChatDirectLinkSlug('link')),
      ).thenThrow(
        const UseChatDirectLinkException(
          UseChatDirectLinkErrorCode.unknownDirectLink,
        ),
      );

      dynamic exception;

      try {
        await chatService.useChatDirectLink(ChatDirectLinkSlug('link'));
      } catch (e) {
        exception = e;
      }

      expect(exception.runtimeType, UseChatDirectLinkException);

      verify(graphQlProvider.useChatDirectLink(ChatDirectLinkSlug('link')));
    },
  );

  tearDownAll(() async {
    await Get.find<CommonDriftProvider>().close();
    await Get.find<ScopedDriftProvider>().close();
    await Get.deleteAll(force: true);
  });
}

final chatData = {
  'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
  'name': 'null',
  'members': {'nodes': [], 'totalCount': 0},
  'kind': 'GROUP',
  'isHidden': false,
  'isArchived': false,
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

final recentChats = {
  'recentChats': {
    'edges': [
      {'node': chatData, 'cursor': 'cursor'},
    ],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    },
  },
};

final favoriteChats = {
  'favoriteChats': {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    },
    'ver': '0',
  },
};

final myUserData = {
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

final blocklist = {
  'edges': [],
  'pageInfo': {
    'endCursor': 'endCursor',
    'hasNextPage': false,
    'startCursor': 'startCursor',
    'hasPreviousPage': false,
  },
};

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
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/provider/drift/account.dart';
import 'package:messenger/provider/drift/background.dart';
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
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/drift/version.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_read_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GraphQlProvider>(onMissingStub: OnMissingStub.returnDefault),
])
void main() async {
  setUp(Get.reset);

  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  final graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(
    graphQlProvider.onStart,
  ).thenReturn(InternalFinalCallback(callback: () {}));
  Get.put<GraphQlProvider>(graphQlProvider);

  final credentialsProvider = Get.put(CredentialsDriftProvider(common));
  final accountProvider = Get.put(AccountDriftProvider(common));
  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final monologProvider = Get.put(MonologDriftProvider(common, scoped));
  final locksProvider = Get.put(LockDriftProvider(common));
  final secretsProvider = Get.put(RefreshSecretDriftProvider(common));

  var chatData = {
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
    'name': null,
    'avatar': null,
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

  var recentChats = {
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

  var favoriteChats = {
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

  when(
    graphQlProvider.recentChatsTopEvents(3),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.recentChatsTopEvents(3, archived: true),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.incomingCallsTopEvents(3),
  ).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

  when(
    graphQlProvider.chatEvents(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      any,
      any,
    ),
  ).thenAnswer((_) => const Stream.empty());

  when(
    graphQlProvider.favoriteChatsEvents(any),
  ).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.getUser(any)).thenAnswer(
    (_) => Future.value(GetUser$Query.fromJson({'user': null}).user),
  );
  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  when(graphQlProvider.chatItem(any)).thenAnswer(
    (_) => Future.value(GetMessage$Query.fromJson({'chatItem': null})),
  );

  AuthService authService = Get.put(
    AuthService(
      Get.put<AbstractAuthRepository>(
        AuthRepository(graphQlProvider, myUserProvider, credentialsProvider),
      ),
      credentialsProvider,
      accountProvider,
      locksProvider,
      secretsProvider,
    ),
  );
  router = RouterState(authService);
  authService.init();

  test('ChatService successfully reads messages', () async {
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

    when(
      graphQlProvider.getChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
    ).thenAnswer(
      (_) => Future.value(GetChat$Query.fromJson({'chat': chatData})),
    );

    when(
      graphQlProvider.readChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const ChatItemId('1'),
      ),
    ).thenAnswer(
      (_) => Future.value(
        ReadChat$Mutation$ReadChat$ChatEventsVersioned.fromJson({
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
                'emails': {'confirmed': []},
                'phones': {'confirmed': []},
                'chatDirectLink': null,
                'hasPassword': false,
                'unreadChatsCount': 0,
                'ver': '0',
                'presence': 'AWAY',
                'online': {'__typename': 'UserOnline'},
                'mutualContactsCount': 0,
                'contacts': [],
                'isDeleted': false,
                'isBlocked': {'ver': '0'},
              },
              'at': DateTime.now().toString(),
            },
          ],
          'ver': '0',
        }),
      ),
    );

    final settingsProvider = Get.put(SettingsDriftProvider(common));
    final userProvider = Get.put(UserDriftProvider(common, scoped));
    final chatItemProvider = Get.put(ChatItemDriftProvider(common, scoped));
    final chatMemberProvider = Get.put(ChatMemberDriftProvider(common, scoped));
    final chatProvider = Get.put(ChatDriftProvider(common, scoped));
    final backgroundProvider = Get.put(BackgroundDriftProvider(common));
    final callCredentialsProvider = Get.put(
      CallCredentialsDriftProvider(common, scoped),
    );
    final chatCredentialsProvider = Get.put(
      ChatCredentialsDriftProvider(common, scoped),
    );
    final callRectProvider = Get.put(CallRectDriftProvider(common, scoped));
    final draftProvider = Get.put(DraftDriftProvider(common, scoped));
    final sessionProvider = Get.put(VersionDriftProvider(common));

    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        backgroundProvider,
        callRectProvider,
        me: const UserId('me'),
      ),
    );
    UserRepository userRepository = Get.put(
      UserRepository(graphQlProvider, userProvider, me: const UserId('me')),
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
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        chatProvider,
        chatItemProvider,
        chatMemberProvider,
        callRepository,
        draftProvider,
        userRepository,
        sessionProvider,
        monologProvider,
        me: const UserId('me'),
      ),
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    await chatService.get(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'));
    await chatService.readChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const ChatItemId('1'),
    );

    verify(
      graphQlProvider.readChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const ChatItemId('1'),
      ),
    );
  });

  test('ChatService does not throw a ReadChatException', () async {
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

    when(
      graphQlProvider.getChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ),
    ).thenAnswer(
      (_) => Future.value(GetChat$Query.fromJson({'chat': chatData})),
    );

    when(
      graphQlProvider.readChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const ChatItemId('0'),
      ),
    ).thenThrow(const ReadChatException(ReadChatErrorCode.unknownChat));

    final settingsProvider = Get.put(SettingsDriftProvider(common));
    final userProvider = Get.put(UserDriftProvider(common, scoped));
    final chatItemProvider = Get.put(ChatItemDriftProvider(common, scoped));
    final chatMemberProvider = Get.put(ChatMemberDriftProvider(common, scoped));
    final chatProvider = Get.put(ChatDriftProvider(common, scoped));
    final backgroundProvider = Get.put(BackgroundDriftProvider(common));
    final callCredentialsProvider = Get.put(
      CallCredentialsDriftProvider(common, scoped),
    );
    final chatCredentialsProvider = Get.put(
      ChatCredentialsDriftProvider(common, scoped),
    );
    final callRectProvider = Get.put(CallRectDriftProvider(common, scoped));
    final draftProvider = Get.put(DraftDriftProvider(common, scoped));
    final sessionProvider = Get.put(VersionDriftProvider(common));

    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        backgroundProvider,
        callRectProvider,
        me: const UserId('me'),
      ),
    );
    UserRepository userRepository = Get.put(
      UserRepository(graphQlProvider, userProvider, me: const UserId('me')),
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
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        chatProvider,
        chatItemProvider,
        chatMemberProvider,
        callRepository,
        draftProvider,
        userRepository,
        sessionProvider,
        monologProvider,
        me: const UserId('me'),
      ),
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));
    await chatService.get(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'));

    await chatService.readChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const ChatItemId('0'),
    );

    verify(
      graphQlProvider.readChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const ChatItemId('0'),
      ),
    );
  });

  tearDown(() async => await Future.wait([common.close(), scoped.close()]));
}

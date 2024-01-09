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
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart' hide ChatMessageTextInput;
import 'package:messenger/api/backend/schema.dart' as api;
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/chat_message_input.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
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
import 'package:messenger/provider/hive/favorite_chat.dart';
import 'package:messenger/provider/hive/session_data.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/monolog.dart';
import 'package:messenger/provider/hive/recent_chat.dart';
import 'package:messenger/provider/hive/credentials.dart';
import 'package:messenger/provider/hive/temp_chat_call_credentials.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_edit_message_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  setUp(Get.reset);

  Hive.init('./test/.temp_hive/chat_edit_message_unit');

  final graphQlProvider = MockGraphQlProvider();

  final credentialsProvider = Get.put(CredentialsHiveProvider());
  await credentialsProvider.init();
  final userProvider = Get.put(UserHiveProvider());
  await userProvider.init();
  final chatProvider = Get.put(ChatHiveProvider());
  await chatProvider.init();
  final callCredentialsProvider = ChatCallCredentialsHiveProvider();
  await callCredentialsProvider.init();
  final tempCallCredentialsProvider = PendingChatCallCredentialsHiveProvider();
  await tempCallCredentialsProvider.init();
  final draftProvider = DraftHiveProvider();
  await draftProvider.init();
  final mediaSettingsProvider = MediaSettingsHiveProvider();
  await mediaSettingsProvider.init();
  final applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  final backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  final callRectProvider = CallRectHiveProvider();
  await callRectProvider.init();
  final monologProvider = MonologHiveProvider();
  await monologProvider.init();
  final recentChatProvider = RecentChatHiveProvider();
  await recentChatProvider.init();
  final favoriteChatProvider = FavoriteChatHiveProvider();
  await favoriteChatProvider.init();
  final sessionProvider = SessionDataHiveProvider();
  await sessionProvider.init();

  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  const chatData = {
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
    'unreadCount': 0,
    'totalCount': 0,
    'ongoingCall': null,
    'ver': '0'
  };

  const recentChats = {
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

  const favoriteChats = {
    'favoriteChats': {
      'edges': [],
      'pageInfo': {
        'endCursor': 'endCursor',
        'hasNextPage': false,
        'startCursor': 'startCursor',
        'hasPreviousPage': false,
      }
    }
  };

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    any,
    any,
  )).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

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

  when(graphQlProvider.getChat(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
  )).thenAnswer(
      (_) => Future.value(GetChat$Query.fromJson({'chat': chatData})));

  when(graphQlProvider.favoriteChatsEvents(any))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.getUser(any))
      .thenAnswer((_) => Future.value(GetUser$Query.fromJson({'user': null})));
  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  test('ChatService successfully edits a ChatMessage', () async {
    final AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        mediaSettingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );

    final AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(graphQlProvider)),
        credentialsProvider,
      ),
    );
    await authService.init();

    final UserRepository userRepository =
        UserRepository(graphQlProvider, userProvider);

    final CallRepository callRepository = Get.put(
      CallRepository(
        graphQlProvider,
        userRepository,
        callCredentialsProvider,
        tempCallCredentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
    );
    final AbstractChatRepository chatRepository =
        Get.put<AbstractChatRepository>(
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
    final ChatService chatService =
        Get.put(ChatService(chatRepository, authService));

    when(graphQlProvider.editChatMessage(
      const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: api.ChatMessageTextInput(kw$new: const ChatMessageText('new text')),
    )).thenAnswer((_) => Future.value());

    await chatService.editChatMessage(
      ChatMessage(
        const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        User(
          const UserId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          UserNum('1234123412341234'),
        ),
        PreciseDateTime.now(),
      ),
      text: const ChatMessageTextInput(ChatMessageText('new text')),
    );

    verify(graphQlProvider.editChatMessage(
      const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: api.ChatMessageTextInput(kw$new: const ChatMessageText('new text')),
    ));
  });

  test(
      'ChatService throws a EditChatMessageException when editing a ChatMessage',
      () async {
    final AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        mediaSettingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );

    final AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(graphQlProvider)),
        credentialsProvider,
      ),
    );
    await authService.init();

    final UserRepository userRepository =
        UserRepository(graphQlProvider, userProvider);

    final CallRepository callRepository = Get.put(
      CallRepository(
        graphQlProvider,
        userRepository,
        callCredentialsProvider,
        tempCallCredentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
    );
    final AbstractChatRepository chatRepository =
        Get.put<AbstractChatRepository>(
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
    final ChatService chatService =
        Get.put(ChatService(chatRepository, authService));

    when(graphQlProvider.editChatMessage(
      const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: api.ChatMessageTextInput(kw$new: const ChatMessageText('new text')),
    )).thenThrow(
      const EditChatMessageException(
        EditChatMessageErrorCode.unknownReplyingChatItem,
      ),
    );

    Get.put(chatProvider);

    expect(
      () async => await chatService.editChatMessage(
        ChatMessage(
          const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          User(
            const UserId('0d72d245-8425-467a-9ebd-082d4f47850b'),
            UserNum('1234123412341234'),
          ),
          PreciseDateTime.now(),
        ),
        text: const ChatMessageTextInput(ChatMessageText('new text')),
      ),
      throwsA(isA<EditChatMessageException>()),
    );

    await Future.delayed(Duration.zero);

    verify(graphQlProvider.editChatMessage(
      const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: api.ChatMessageTextInput(kw$new: const ChatMessageText('new text')),
    ));
  });
}

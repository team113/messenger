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
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/image_gallery_item.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/model/chat.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_split_message_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  setUp(Get.reset);

  Hive.init('./test/.temp_hive/chat_split_message_unit');

  final graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  var galleryItemProvider = Get.put(GalleryItemHiveProvider());
  await galleryItemProvider.init();
  var chatHiveProvider = Get.put(ChatHiveProvider());
  await chatHiveProvider.init();
  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  var myUserProvider = Get.put(MyUserHiveProvider());
  await myUserProvider.init();
  await myUserProvider.clear();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  await userProvider.clear();

  var myUserData = {
    'id': '08164fb1-ff60-49f6-8ff2-7fede51c3aed',
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
    'currentCall': null,
    'ver': '0'
  };

  var recentChats = {
    'recentChats': {
      'nodes': [chatData]
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

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));
  when(graphQlProvider.keepOnline())
      .thenAnswer((_) => Future.value(const Stream.empty()));

  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    ChatVersion('0'),
  )).thenAnswer((_) => Future.value(const Stream.empty()));

  AuthService authService = Get.put(
    AuthService(
      Get.put<AbstractAuthRepository>(AuthRepository(graphQlProvider)),
      sessionProvider,
    ),
  );
  await authService.init();

  AbstractMyUserRepository myUserRepository =
      MyUserRepository(graphQlProvider, myUserProvider, galleryItemProvider);
  MyUserService myUserService =
      Get.put(MyUserService(authService, myUserRepository));

  const maxText = ChatService.maxMessageText;

  test('ChatService successfully sends 1 message at $maxText symbols',
      () async {
    final message = ChatMessageText('A' * maxText);
    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(graphQlProvider.postChatMessage(
            const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
            text: message,
            attachments: anyNamed('attachments'),
            repliesTo:
                const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer(
      (_) => Future.value(),
    );

    Get.put(chatHiveProvider);
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
      ),
    );
    ChatService chatService =
        Get.put(ChatService(chatRepository, myUserService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: [],
      repliesTo: ChatMessage(
        const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const ChatId('2'),
        const UserId('3'),
        PreciseDateTime.now(),
      ),
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: anyNamed('attachments'),
      repliesTo: const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).called(1);
  });

  test('ChatService successfully sends 2 messages at $maxText symbols and 1 symbol',
      () async {
    final message = ChatMessageText('A' * (maxText + 1));
    const message1 = ChatMessageText('A');
    final message2 = ChatMessageText('A' * maxText);

    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(graphQlProvider.postChatMessage(
            const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
            text: message2,
            attachments: anyNamed('attachments'),
            repliesTo:
                const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer((_) => Future.value());

    when(graphQlProvider.postChatMessage(
            const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
            text: message1,
            attachments: anyNamed('attachments'),
            repliesTo:
                const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer((_) => Future.value());

    Get.put(chatHiveProvider);
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
      ),
    );
    ChatService chatService =
        Get.put(ChatService(chatRepository, myUserService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: [],
      repliesTo: ChatMessage(
        const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const ChatId('2'),
        const UserId('3'),
        PreciseDateTime.now(),
      ),
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message2,
      attachments: anyNamed('attachments'),
      repliesTo: const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).called(1);

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message1,
      attachments: anyNamed('attachments'),
      repliesTo: const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).called(1);
  });

  test(
      'ChatService successfully sends 3 messages at $maxText symbols, $maxText symbols and 1 symbol',
      () async {
    final message = ChatMessageText('A' * (maxText * 2 + 1));
    final message1 = ChatMessageText('A' * maxText);
    const message2 = ChatMessageText('A');

    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(graphQlProvider.postChatMessage(
            const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
            text: message1,
            attachments: anyNamed('attachments'),
            repliesTo:
                const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer((_) => Future.value());

    when(graphQlProvider.postChatMessage(
            const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
            text: message2,
            attachments: anyNamed('attachments'),
            repliesTo:
                const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer((_) => Future.value());

    Get.put(chatHiveProvider);
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
      ),
    );
    ChatService chatService =
        Get.put(ChatService(chatRepository, myUserService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: [],
      repliesTo: ChatMessage(
        const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const ChatId('2'),
        const UserId('3'),
        PreciseDateTime.now(),
      ),
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message1,
      attachments: anyNamed('attachments'),
      repliesTo: const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).called(2);

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message2,
      attachments: anyNamed('attachments'),
      repliesTo: const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).called(1);
  });

  test('ChatService successfully sends 1 message at 1 attachment', () async {
    final attachment = FileAttachment(
      id: const AttachmentId('test'),
      filename: 'test.test',
      original: const Original('test'),
      size: 100,
    );

    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(graphQlProvider.postChatMessage(
            const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
            attachments: [attachment.id],
            repliesTo:
                const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer((_) => Future.value());

    Get.put(chatHiveProvider);

    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
      ),
    );
    ChatService chatService =
        Get.put(ChatService(chatRepository, myUserService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      attachments: [attachment],
      repliesTo: ChatMessage(
        const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const ChatId('2'),
        const UserId('3'),
        PreciseDateTime.now(),
      ),
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      attachments: [attachment.id],
      repliesTo: const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).called(1);
  });

  test(
      'ChatService successfully sends 1 message at $maxText symbols and 1 attachment',
      () async {
    final message = ChatMessageText('A' * maxText);
    final attachment = FileAttachment(
      id: const AttachmentId('test'),
      filename: 'test.test',
      original: const Original('test'),
      size: 100,
    );

    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(graphQlProvider.postChatMessage(
            const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
            text: message,
            attachments: [attachment.id],
            repliesTo:
                const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer((_) => Future.value());

    Get.put(chatHiveProvider);
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
      ),
    );
    ChatService chatService =
        Get.put(ChatService(chatRepository, myUserService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: [attachment],
      repliesTo: ChatMessage(
        const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const ChatId('2'),
        const UserId('3'),
        PreciseDateTime.now(),
      ),
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: [attachment.id],
      repliesTo: const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).called(1);
  });

  test(
      'ChatService successfully sends 2 messages at $maxText symbols and 1 symbol with 3 attachments',
      () async {
    final message = ChatMessageText('A' * (maxText + 1));
    final message1 = ChatMessageText('A' * maxText);
    const message2 = ChatMessageText('A');
    final attachments = List.generate(
      3,
      (index) => FileAttachment(
        id: const AttachmentId('test'),
        filename: 'test.test',
        original: const Original('test'),
        size: 100,
      ),
    );

    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(graphQlProvider.postChatMessage(
            const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
            text: message1,
            repliesTo:
                const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer((_) => Future.value());

    when(graphQlProvider.postChatMessage(
            const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
            text: message2,
            attachments: attachments.map((a) => a.id).toList(),
            repliesTo:
                const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer((_) => Future.value());

    Get.put(chatHiveProvider);
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
      ),
    );
    ChatService chatService =
        Get.put(ChatService(chatRepository, myUserService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: attachments,
      repliesTo: ChatMessage(
        const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        const ChatId('2'),
        const UserId('3'),
        PreciseDateTime.now(),
      ),
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message1,
      repliesTo: const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).called(1);

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message2,
      attachments: attachments.map((a) => a.id).toList(),
      repliesTo: const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).called(1);
  });
}

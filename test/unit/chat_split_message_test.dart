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
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/file.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/model/chat.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/platform_utils.dart';
import 'chat_split_message_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  PlatformUtils = PlatformUtilsMock();
  Hive.init('./test/.temp_hive/chat_split_message_unit');

  const int maxText = ChatMessageText.maxLength;

  final graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  var galleryItemProvider = Get.put(GalleryItemHiveProvider(), permanent: true);
  await galleryItemProvider.init();
  var chatHiveProvider = Get.put(ChatHiveProvider(), permanent: true);
  await chatHiveProvider.init();
  await chatHiveProvider.clear();
  var sessionProvider = Get.put(SessionDataHiveProvider(), permanent: true);
  await sessionProvider.init();
  var userProvider = Get.put(UserHiveProvider(), permanent: true);
  await userProvider.init();
  await userProvider.clear();

  AuthService authService = Get.put(
    AuthService(
      Get.put<AbstractAuthRepository>(AuthRepository(graphQlProvider)),
      sessionProvider,
    ),
    permanent: true,
  );
  await authService.init();

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
      .thenAnswer((_) => Future.value(const Stream.empty()));
  when(graphQlProvider.keepOnline())
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

  test('ChatService doesn\'t split message with $maxText symbols', () async {
    final ChatMessageText message = ChatMessageText('A' * maxText);

    when(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: anyNamed('attachments'),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).thenAnswer((_) => Future.value());

    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('me'),
      ),
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: [],
      repliesTo: [
        ChatMessage(
          const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          const ChatId('2'),
          const UserId('3'),
          PreciseDateTime.now(),
        ),
      ],
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: anyNamed('attachments'),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).called(1);
  });

  test('ChatService splits ($maxText + 1) symbols into 2 messages', () async {
    final ChatMessageText message = ChatMessageText('A' * (maxText + 1));
    const ChatMessageText message1 = ChatMessageText('A');
    final ChatMessageText message2 = ChatMessageText('A' * maxText);

    when(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message2,
      attachments: anyNamed('attachments'),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).thenAnswer((_) => Future.value());

    when(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message1,
      attachments: anyNamed('attachments'),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).thenAnswer((_) => Future.value());

    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('me'),
      ),
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: [],
      repliesTo: [
        ChatMessage(
          const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          const ChatId('2'),
          const UserId('3'),
          PreciseDateTime.now(),
        ),
      ],
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message2,
      attachments: anyNamed('attachments'),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).called(1);

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message1,
      attachments: anyNamed('attachments'),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).called(1);
  });

  test('ChatService splits (2 * $maxText + 1) symbols into 3 messages',
      () async {
    final ChatMessageText message = ChatMessageText('A' * (maxText * 2 + 1));
    final ChatMessageText message1 = ChatMessageText('A' * maxText);
    const ChatMessageText message2 = ChatMessageText('A');

    when(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message1,
      attachments: anyNamed('attachments'),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).thenAnswer((_) => Future.value());

    when(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message2,
      attachments: anyNamed('attachments'),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).thenAnswer((_) => Future.value());

    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('me'),
      ),
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: [],
      repliesTo: [
        ChatMessage(
          const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          const ChatId('2'),
          const UserId('3'),
          PreciseDateTime.now(),
        ),
      ],
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message1,
      attachments: anyNamed('attachments'),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).called(2);

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message2,
      attachments: anyNamed('attachments'),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).called(1);
  });

  test('ChatService doesn\'t split message with attachment and reply',
      () async {
    final attachment = FileAttachment(
      id: const AttachmentId('test'),
      filename: 'test.test',
      original: StorageFile(relativeRef: 'test', size: 100),
    );

    when(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      attachments: [attachment.id],
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).thenAnswer((_) => Future.value());

    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('me'),
      ),
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      attachments: [attachment],
      repliesTo: [
        ChatMessage(
          const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          const ChatId('2'),
          const UserId('3'),
          PreciseDateTime.now(),
        ),
      ],
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      attachments: [attachment.id],
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).called(1);
  });

  test('ChatService doesn\'t split message with attachment', () async {
    final ChatMessageText message = ChatMessageText('A' * maxText);
    final FileAttachment attachment = FileAttachment(
      id: const AttachmentId('test'),
      filename: 'test.test',
      original: StorageFile(relativeRef: 'test', size: 100),
    );

    when(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: [attachment.id],
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).thenAnswer((_) => Future.value());

    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('me'),
      ),
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: [attachment],
      repliesTo: [
        ChatMessage(
          const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          const ChatId('2'),
          const UserId('3'),
          PreciseDateTime.now(),
        ),
      ],
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: [attachment.id],
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).called(1);
  });

  test('ChatService splits with ($maxText + 1) symbols and 3 attachments',
      () async {
    final ChatMessageText message = ChatMessageText('A' * (maxText + 1));
    final ChatMessageText message1 = ChatMessageText('A' * maxText);
    const ChatMessageText message2 = ChatMessageText('A');
    final List<Attachment> attachments = List.generate(
      3,
      (index) => FileAttachment(
        id: const AttachmentId('test'),
        filename: 'test.test',
        original: StorageFile(relativeRef: 'test', size: 100),
      ),
    );

    when(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message1,
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).thenAnswer((_) => Future.value());

    when(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message2,
      attachments: attachments.map((a) => a.id).toList(),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).thenAnswer((_) => Future.value());

    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        userRepository,
        me: const UserId('me'),
      ),
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    await Future.delayed(Duration.zero);

    await chatService.sendChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message,
      attachments: attachments,
      repliesTo: [
        ChatMessage(
          const ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          const ChatId('2'),
          const UserId('3'),
          PreciseDateTime.now(),
        ),
      ],
    );

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message1,
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).called(1);

    verify(graphQlProvider.postChatMessage(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      text: message2,
      attachments: attachments.map((a) => a.id).toList(),
      repliesTo: const [ChatItemId('0d72d245-8425-467a-9ebd-082d4f47850b')],
    )).called(1);
  });
}

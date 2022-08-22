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
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/gql/exceptions.dart';
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

import 'chat_rename_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  setUp(Get.reset);

  Hive.init('./test/.temp_hive/chat_renamte_unit');

  final graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  var galleryItemProvider = GalleryItemHiveProvider();
  await galleryItemProvider.init();
  var chatHiveProvider = ChatHiveProvider();
  await chatHiveProvider.init();
  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  var myUserProvider = Get.put(MyUserHiveProvider());
  await myUserProvider.init();
  await myUserProvider.clear();
  var userProvider = UserHiveProvider();
  await userProvider.init();

  var myUserData = {
    'id': 'id',
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

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));
  when(graphQlProvider.keepOnline())
      .thenAnswer((_) => Future.value(const Stream.empty()));

  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    ChatVersion('0'),
  )).thenAnswer((_) => Future.value(const Stream.empty()));

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

  when(graphQlProvider.recentChats(
    first: 120,
    after: null,
    last: null,
    before: null,
  )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

  when(graphQlProvider.getChat(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
  )).thenAnswer((_) => Future.value(GetChat$Query.fromJson(chatData)));

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

  test('ChatService successfully changes chat name', () async {
    when(graphQlProvider.renameChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ChatName('newname'),
    )).thenAnswer((_) => Future.value(
          (RenameChat$Mutation.fromJson({
            'renameChat': {
              '__typename': 'ChatEventsVersioned',
              'events': [
                {
                  '__typename': 'EventChatRenamed',
                  'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                  'name': 'newname',
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
              'ver': '1'
            }
          }).renameChat as RenameChat$Mutation$RenameChat$ChatEventsVersioned),
        ));

    Get.put(chatHiveProvider);
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
        ChatRepository(graphQlProvider, Get.find(), userRepository));
    ChatService chatService =
        Get.put(ChatService(chatRepository, myUserService));

    await chatService.renameChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ChatName('newname'),
    );

    verify(graphQlProvider.renameChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ChatName('newname'),
    ));
  });

  test('ChatService throws a RenameChatException on chat rename', () async {
    when(graphQlProvider.renameChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ChatName('newname'),
    )).thenThrow(const RenameChatException(RenameChatErrorCode.unknownChat));

    Get.put(chatHiveProvider);
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
        ChatRepository(graphQlProvider, Get.find(), userRepository));
    ChatService chatService =
        Get.put(ChatService(chatRepository, myUserService));

    expect(
      () async => await chatService.renameChat(
        const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
        ChatName('newname'),
      ),
      throwsA(isA<RenameChatException>()),
    );

    verify(graphQlProvider.renameChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ChatName('newname'),
    ));
  });
}

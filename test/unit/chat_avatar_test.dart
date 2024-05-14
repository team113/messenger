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

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/account.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
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
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_avatar_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  setUp(Get.reset);

  final DriftProvider database = DriftProvider(NativeDatabase.memory());

  Hive.init('./test/.temp_hive/chat_avatar_unit');

  var credentialsProvider = CredentialsHiveProvider();
  await credentialsProvider.init();

  final graphQlProvider = MockGraphQlProvider();
  Get.put<GraphQlProvider>(graphQlProvider);
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  await myUserProvider.clear();
  var chatHiveProvider = ChatHiveProvider();
  await chatHiveProvider.init();
  await chatHiveProvider.clear();
  final userProvider = UserDriftProvider(database);
  final callCredentialsProvider = CallCredentialsHiveProvider();
  await callCredentialsProvider.init();
  final chatCredentialsProvider = ChatCredentialsHiveProvider();
  await chatCredentialsProvider.init();
  var draftProvider = DraftHiveProvider();
  await draftProvider.init();
  await draftProvider.clear();
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
  var recentChatProvider = RecentChatHiveProvider();
  await recentChatProvider.init();
  var favoriteChatProvider = FavoriteChatHiveProvider();
  await favoriteChatProvider.init();
  var sessionProvider = SessionDataHiveProvider();
  await sessionProvider.init();
  final accountProvider = AccountHiveProvider();
  await accountProvider.init();

  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());

  test('ChatService successfully adds and resets chat avatar', () async {
    when(graphQlProvider.updateChatAvatar(
      const ChatId('123'),
      file: null,
      onSendProgress: null,
    )).thenAnswer(
      (_) => Future.value(UpdateChatAvatar$Mutation.fromJson({
        'updateChatAvatar': {
          '__typename': 'ChatEventsVersioned',
          'events': [
            {
              'chatId': '123',
              'byUser': userData,
              'at': DateTime.now().toString(),
            }
          ],
          'ver': '2'
        }
      }).updateChatAvatar as ChatEventsVersionedMixin?),
    );

    when(graphQlProvider.updateChatAvatar(
      const ChatId('123'),
      file: captureThat(isNotNull, named: 'file'),
      onSendProgress: null,
    )).thenAnswer(
      (_) => Future.value(UpdateChatAvatar$Mutation.fromJson({
        'updateChatAvatar': {
          '__typename': 'ChatEventsVersioned',
          'events': [
            {
              'chatId': '123',
              'avatar': {
                'full': {'relativeRef': ''},
                'big': {'relativeRef': ''},
                'medium': {'relativeRef': ''},
                'small': {'relativeRef': ''},
                'original': {'relativeRef': ''},
              },
              'byUser': userData,
              'at': DateTime.now().toString(),
            }
          ],
          'ver': '1'
        }
      }).updateChatAvatar as ChatEventsVersionedMixin?),
    );

    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        mediaSettingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
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

    final UserRepository userRepository =
        UserRepository(graphQlProvider, userProvider);
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
    final ChatRepository chatRepository = ChatRepository(
      graphQlProvider,
      chatHiveProvider,
      recentChatProvider,
      favoriteChatProvider,
      callRepository,
      draftProvider,
      userRepository,
      sessionProvider,
      monologProvider,
      me: const UserId('me'),
    );

    final ChatService chatService = ChatService(chatRepository, authService);

    await chatService.updateChatAvatar(
      const ChatId('123'),
      file: NativeFile(
        name: 'test',
        size: 2,
        bytes: Uint8List.fromList([1, 1]),
      ),
      onSendProgress: null,
    );

    await chatService.updateChatAvatar(
      const ChatId('123'),
      file: null,
      onSendProgress: null,
    );

    verifyInOrder([
      graphQlProvider.updateChatAvatar(
        const ChatId('123'),
        file: captureThat(isNotNull, named: 'file'),
        onSendProgress: null,
      ),
      graphQlProvider.updateChatAvatar(
        const ChatId('123'),
        file: null,
        onSendProgress: null,
      ),
    ]);
  });

  test(
      'ChatService throws UpdateChatAvatarErrorCode.tooBigSize, UpdateChatAvatarErrorCode.unknownChat',
      () async {
    when(graphQlProvider.updateChatAvatar(
      const ChatId('123'),
      file: captureThat(isNotNull, named: 'file'),
      onSendProgress: null,
    )).thenThrow(
      const UpdateChatAvatarException(UpdateChatAvatarErrorCode.invalidSize),
    );

    when(graphQlProvider.updateChatAvatar(
      const ChatId('123'),
      file: null,
      onSendProgress: null,
    )).thenThrow(
      const UpdateChatAvatarException(UpdateChatAvatarErrorCode.unknownChat),
    );

    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        mediaSettingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
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

    final UserRepository userRepository =
        UserRepository(graphQlProvider, userProvider);
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
    final ChatRepository chatRepository = ChatRepository(
      graphQlProvider,
      chatHiveProvider,
      recentChatProvider,
      favoriteChatProvider,
      callRepository,
      draftProvider,
      userRepository,
      sessionProvider,
      monologProvider,
      me: const UserId('me'),
    );

    final ChatService chatService = ChatService(chatRepository, authService);

    Object? exception;

    try {
      await chatService.updateChatAvatar(
        const ChatId('123'),
        file: NativeFile(
          name: 'test',
          size: 2,
          bytes: Uint8List.fromList([1, 1]),
        ),
        onSendProgress: null,
      );
    } catch (e) {
      exception = e;
    }

    if (exception !=
        const UpdateChatAvatarException(
            UpdateChatAvatarErrorCode.invalidSize)) {
      fail('UpdateChatAvatarErrorCode.tooBigSize not thrown');
    }

    try {
      await chatService.updateChatAvatar(
        const ChatId('123'),
        file: null,
        onSendProgress: null,
      );
    } catch (e) {
      exception = e;
    }

    if (exception !=
        const UpdateChatAvatarException(
            UpdateChatAvatarErrorCode.unknownChat)) {
      fail('UpdateChatAvatarErrorCode.unknownChat not thrown');
    }

    verifyInOrder([
      graphQlProvider.updateChatAvatar(
        const ChatId('123'),
        file: captureThat(isNotNull, named: 'file'),
        onSendProgress: null,
      ),
      graphQlProvider.updateChatAvatar(
        const ChatId('123'),
        file: null,
        onSendProgress: null,
      ),
    ]);
  });

  tearDown(() async => await database.close());
}

final userData = {
  '__typename': 'User',
  'id': '6a9e0b6e-61ab-43cb-a8d4-dabaf065e5a3',
  'num': '7461878581615099',
  'name': 'user',
  'avatar': null,
  'callCover': null,
  'mutualContactsCount': 0,
  'contacts': [],
  'online': {'__typename': 'UserOnline'},
  'presence': 'PRESENT',
  'status': null,
  'isDeleted': false,
  'dialog': null,
  'isBlocked': {'ver': '1'},
  'ver': '2'
};

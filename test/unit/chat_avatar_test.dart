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

import 'dart:typed_data';

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
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
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
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'my_profile_gallery_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  Hive.init('./test/.temp_hive/chat_avatar_unit');
  var userData = {
    '__typename': 'User',
    'id': '6a9e0b6e-61ab-43cb-a8d4-dabaf065e5a3',
    'num': '7461878581615099',
    'name': 'user',
    'bio': null,
    'avatar': null,
    'callCover': null,
    'gallery': {'nodes': []},
    'mutualContactsCount': 0,
    'online': {'__typename': 'UserOnline'},
    'presence': 'PRESENT',
    'status': null,
    'isDeleted': false,
    'dialog': null,
    'isBlacklisted': {'blacklisted': false, 'ver': '1'},
    'ver': '2'
  };

  var sessionProvider = SessionDataHiveProvider();
  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  await sessionProvider.init();

  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  await myUserProvider.clear();
  var chatHiveProvider = ChatHiveProvider();
  await chatHiveProvider.init();
  await chatHiveProvider.clear();
  var userHiveProvider = UserHiveProvider();
  await userHiveProvider.init();
  await userHiveProvider.clear();
  var galleryItemProvider = GalleryItemHiveProvider();
  await galleryItemProvider.init();
  await galleryItemProvider.clear();
  var credentialsProvider = ChatCallCredentialsHiveProvider();
  await credentialsProvider.init();
  var draftProvider = DraftHiveProvider();
  await draftProvider.init();
  await draftProvider.clear();
  var mediaSettingsProvider = MediaSettingsHiveProvider();
  await mediaSettingsProvider.init();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();

  Get.put(myUserProvider);
  Get.put(galleryItemProvider);
  Get.put(userHiveProvider);
  Get.put(chatHiveProvider);
  Get.put(sessionProvider);
  Get.put<GraphQlProvider>(graphQlProvider);

  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));

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
      ),
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    await authService.init();

    UserRepository userRepository = UserRepository(
      graphQlProvider,
      userHiveProvider,
      galleryItemProvider,
    );
    CallRepository callRepository = Get.put(
      CallRepository(
        graphQlProvider,
        userRepository,
        credentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
    );
    ChatRepository chatRepository = ChatRepository(
      graphQlProvider,
      chatHiveProvider,
      callRepository,
      draftProvider,
      userRepository,
      sessionProvider,
    );

    ChatService chatService = ChatService(
      chatRepository,
      authService,
      userRepository,
    );

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
      const UpdateChatAvatarException(UpdateChatAvatarErrorCode.tooBigSize),
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
      ),
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    await authService.init();

    UserRepository userRepository = UserRepository(
      graphQlProvider,
      userHiveProvider,
      galleryItemProvider,
    );
    CallRepository callRepository = Get.put(
      CallRepository(
        graphQlProvider,
        userRepository,
        credentialsProvider,
        settingsRepository,
        me: const UserId('me'),
      ),
    );
    ChatRepository chatRepository = ChatRepository(
      graphQlProvider,
      chatHiveProvider,
      callRepository,
      draftProvider,
      userRepository,
      sessionProvider,
    );

    ChatService chatService = ChatService(
      chatRepository,
      authService,
      userRepository,
    );

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
        const UpdateChatAvatarException(UpdateChatAvatarErrorCode.tooBigSize)) {
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
}

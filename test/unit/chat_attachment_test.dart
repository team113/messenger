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
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/native_file.dart';
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
import 'package:messenger/provider/hive/calls_preferences.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_call_credentials.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/model/chat.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_attachment_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  setUp(Get.reset);

  Hive.init('./test/.temp_hive/chat_attachment_unit');

  final graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  var galleryItemProvider = GalleryItemHiveProvider();
  await galleryItemProvider.init();
  var chatHiveProvider = ChatHiveProvider();
  await chatHiveProvider.init();
  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  var credentialsProvider = ChatCallCredentialsHiveProvider();
  await credentialsProvider.init();
  var draftProvider = DraftHiveProvider();
  await draftProvider.init();
  var mediaSettingsProvider = MediaSettingsHiveProvider();
  await mediaSettingsProvider.init();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  var callsPreferences = CallsPreferencesHiveProvider();
  await callsPreferences.init();

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
  when(graphQlProvider.incomingCallsTopEvents(3))
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

  test('ChatService successfully uploads an attachment', () async {
    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(graphQlProvider.getChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).thenAnswer((_) => Future.value(GetChat$Query.fromJson(chatData)));

    when(graphQlProvider.uploadAttachment(
      any,
      onSendProgress: anyNamed('onSendProgress'),
    )).thenAnswer(
      (_) => Future.value(
        UploadAttachment$Mutation$UploadAttachment$UploadAttachmentOk.fromJson({
          '__typename': 'UploadAttachmentOk',
          'attachment': {
            '__typename': 'ImageAttachment',
            'id': 'e8d111f0-4a27-405d-8a4a-0a66d20e9098',
            'filename': 'filename',
            'original': {'relativeRef': 'orig.jpg'},
            'big': {'relativeRef': 'orig.jpg'},
            'medium': {'relativeRef': 'orig.jpg'},
            'small': {'relativeRef': 'orig.jpg'},
          }
        }),
      ),
    );

    when(graphQlProvider.favoriteChatsEvents(null)).thenAnswer(
      (_) => Future.value(const Stream.empty()),
    );

    Get.put(chatHiveProvider);

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
        callsPreferences,
        me: const UserId('me'),
      ),
    );
    AbstractChatRepository chatRepository =
        Get.put<AbstractChatRepository>(ChatRepository(
      graphQlProvider,
      Get.find(),
      callRepository,
      draftProvider,
      userRepository,
      sessionProvider,
    ));
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    await chatService.uploadAttachment(
      LocalAttachment(
        NativeFile(
          bytes: Uint8List.fromList([1, 1]),
          size: 2,
          name: 'test',
        ),
      ),
    );

    verify(graphQlProvider.uploadAttachment(any,
        onSendProgress: anyNamed('onSendProgress')));
  });

  test('ChatService throws an UploadAttachmentException', () async {
    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

    when(graphQlProvider.getChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).thenAnswer((_) => Future.value(GetChat$Query.fromJson(chatData)));

    when(graphQlProvider.uploadAttachment(
      any,
      onSendProgress: anyNamed('onSendProgress'),
    )).thenThrow(
      const UploadAttachmentException(UploadAttachmentErrorCode.artemisUnknown),
    );

    Get.put(chatHiveProvider);

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
        callsPreferences,
        me: const UserId('me'),
      ),
    );
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        Get.find(),
        callRepository,
        draftProvider,
        userRepository,
        sessionProvider,
      ),
    );
    ChatService chatService = Get.put(ChatService(chatRepository, authService));

    var attachment = LocalAttachment(
      NativeFile(
        bytes: Uint8List.fromList([1, 1]),
        size: 2,
        name: 'test',
      ),
    );
    attachment.upload.value = Completer();
    attachment.upload.value?.future.then((_) {}, onError: (_) {});
    await expectLater(
      () async => await chatService.uploadAttachment(attachment),
      throwsA(isA<UploadAttachmentException>()),
    );

    verify(
      graphQlProvider.uploadAttachment(
        any,
        onSendProgress: anyNamed('onSendProgress'),
      ),
    );
  });
}

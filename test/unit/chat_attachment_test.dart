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
import 'package:messenger/provider/drift/background.dart';
import 'package:messenger/provider/drift/chat.dart';
import 'package:messenger/provider/drift/chat_item.dart';
import 'package:messenger/provider/drift/chat_member.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/my_user.dart';
import 'package:messenger/provider/drift/settings.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/account.dart';
import 'package:messenger/provider/hive/call_credentials.dart';
import 'package:messenger/provider/hive/call_rect.dart';
import 'package:messenger/provider/hive/chat_credentials.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/session_data.dart';
import 'package:messenger/provider/hive/monolog.dart';
import 'package:messenger/provider/hive/credentials.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_attachment_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  Get.reset();

  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  Hive.init('./test/.temp_hive/chat_attachment_unit');

  final graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  var credentialsProvider = Get.put(CredentialsHiveProvider());
  await credentialsProvider.init();
  final settingsProvider = Get.put(SettingsDriftProvider(common));
  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final userProvider = Get.put(UserDriftProvider(common, scoped));
  final chatItemProvider = Get.put(ChatItemDriftProvider(common, scoped));
  final chatMemberProvider = Get.put(ChatMemberDriftProvider(common, scoped));
  final chatProvider = Get.put(ChatDriftProvider(common, scoped));
  final backgroundProvider = Get.put(BackgroundDriftProvider(common));
  final callCredentialsProvider = CallCredentialsHiveProvider();
  await callCredentialsProvider.init();
  final chatCredentialsProvider = ChatCredentialsHiveProvider();
  await chatCredentialsProvider.init();
  var draftProvider = DraftHiveProvider();
  await draftProvider.init();
  var callRectProvider = CallRectHiveProvider();
  await callRectProvider.init();
  var monologProvider = MonologHiveProvider();
  await monologProvider.init();
  var sessionProvider = SessionDataHiveProvider();
  await sessionProvider.init();
  final accountProvider = AccountHiveProvider();
  await accountProvider.init();

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());
  when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    any,
    any,
  )).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.getUser(any))
      .thenAnswer((_) => Future.value(GetUser$Query.fromJson({'user': null})));
  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  final AuthService authService = Get.put(
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

  test('ChatService successfully uploads an attachment', () async {
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
      (_) => Future.value(FavoriteChats$Query.fromJson(favoriteChats)),
    );

    when(graphQlProvider.getChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).thenAnswer(
      (_) => Future.value(GetChat$Query.fromJson({'chat': chatData})),
    );

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

    when(graphQlProvider.favoriteChatsEvents(any)).thenAnswer(
      (_) => const Stream.empty(),
    );

    Get.put<GraphQlProvider>(graphQlProvider);

    final AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        const UserId('me'),
        settingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );

    final UserRepository userRepository =
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
    final AbstractChatRepository chatRepository =
        Get.put<AbstractChatRepository>(ChatRepository(
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
    ));
    final ChatService chatService = Get.put(
      ChatService(chatRepository, authService),
    );

    await chatService.uploadAttachment(
      LocalAttachment(
        NativeFile(
          bytes: Uint8List.fromList([1, 1]),
          size: 2,
          name: 'test',
        ),
      ),
    );

    verify(graphQlProvider.uploadAttachment(
      any,
      onSendProgress: anyNamed('onSendProgress'),
    ));
  });

  test('ChatService throws an UploadAttachmentException', () async {
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
      (_) => Future.value(FavoriteChats$Query.fromJson(favoriteChats)),
    );

    when(graphQlProvider.getChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).thenAnswer(
      (_) => Future.value(GetChat$Query.fromJson({'chat': chatData})),
    );

    when(graphQlProvider.uploadAttachment(
      any,
      onSendProgress: anyNamed('onSendProgress'),
    )).thenThrow(
      const UploadAttachmentException(UploadAttachmentErrorCode.artemisUnknown),
    );

    Get.put<GraphQlProvider>(graphQlProvider);

    final AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        const UserId('me'),
        settingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );

    final UserRepository userRepository =
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
        sessionProvider,
        monologProvider,
        me: const UserId('me'),
      ),
    );

    final ChatService chatService = Get.put(
      ChatService(chatRepository, authService),
    );

    final attachment = LocalAttachment(
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

  tearDown(() async => await Future.wait([common.close(), scoped.close()]));
}

final chatData = {
  'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
  'name': null,
  'avatar': null,
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
};

final recentChats = {
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

final favoriteChats = {
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

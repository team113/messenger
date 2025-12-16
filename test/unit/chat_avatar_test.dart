// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
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

import 'chat_avatar_test.mocks.dart';

@GenerateNiceMocks([MockSpec<GraphQlProvider>()])
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
  final settingsProvider = Get.put(SettingsDriftProvider(common));
  final myUserProvider = Get.put(MyUserDriftProvider(common));
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
  final monologProvider = Get.put(MonologDriftProvider(common, scoped));
  final sessionProvider = Get.put(VersionDriftProvider(common));
  final locksProvider = Get.put(LockDriftProvider(common));

  when(
    graphQlProvider.incomingCallsTopEvents(3),
  ).thenAnswer((_) => const Stream.empty());

  test('ChatService successfully adds and resets chat avatar', () async {
    when(
      graphQlProvider.updateChatAvatar(
        const ChatId('123'),
        file: null,
        onSendProgress: null,
      ),
    ).thenAnswer(
      (_) => Future.value(
        UpdateChatAvatar$Mutation.fromJson({
              'updateChatAvatar': {
                '__typename': 'ChatEventsVersioned',
                'events': [
                  {
                    'chatId': '123',
                    'byUser': userData,
                    'at': DateTime.now().toString(),
                  },
                ],
                'ver': '2',
              },
            }).updateChatAvatar
            as ChatEventsVersionedMixin?,
      ),
    );

    when(
      graphQlProvider.updateChatAvatar(
        const ChatId('123'),
        file: captureThat(isNotNull, named: 'file'),
        onSendProgress: null,
      ),
    ).thenAnswer(
      (_) => Future.value(
        UpdateChatAvatar$Mutation.fromJson({
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
                  },
                ],
                'ver': '1',
              },
            }).updateChatAvatar
            as ChatEventsVersionedMixin?,
      ),
    );

    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        const UserId('me'),
        settingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(
          AuthRepository(graphQlProvider, myUserProvider, credentialsProvider),
        ),
        credentialsProvider,
        accountProvider,
        locksProvider,
      ),
    );
    router = RouterState(authService);
    authService.init();

    final UserRepository userRepository = UserRepository(
      graphQlProvider,
      userProvider,
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
    final ChatRepository chatRepository = ChatRepository(
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

  test('ChatService throws UpdateChatAvatarErrorCode.tooBigSize', () async {
    when(
      graphQlProvider.updateChatAvatar(
        const ChatId('123'),
        file: captureThat(isNotNull, named: 'file'),
        onSendProgress: null,
      ),
    ).thenThrow(
      const UpdateChatAvatarException(UpdateChatAvatarErrorCode.invalidSize),
    );

    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        const UserId('me'),
        settingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(
          AuthRepository(graphQlProvider, myUserProvider, credentialsProvider),
        ),
        credentialsProvider,
        accountProvider,
        locksProvider,
      ),
    );
    authService.init();

    final UserRepository userRepository = UserRepository(
      graphQlProvider,
      userProvider,
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
    final ChatRepository chatRepository = ChatRepository(
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
          UpdateChatAvatarErrorCode.invalidSize,
        )) {
      fail('UpdateChatAvatarErrorCode.tooBigSize not thrown');
    }

    verifyInOrder([
      graphQlProvider.updateChatAvatar(
        const ChatId('123'),
        file: captureThat(isNotNull, named: 'file'),
        onSendProgress: null,
      ),
    ]);
  });

  tearDown(() async => await Future.wait([common.close(), scoped.close()]));
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
  'ver': '2',
};

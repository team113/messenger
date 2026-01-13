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

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql/client.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_call.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
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
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/model/chat.dart';
import 'package:messenger/store/model/user.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';

import '../mock/graphql_provider.dart';

late CommonDriftProvider common;
late ScopedDriftProvider scoped;

void main() async {
  setUp(() {
    Get.reset();
    common = CommonDriftProvider.memory();
    scoped = ScopedDriftProvider.memory();
  });

  test('CallService registers and handles all ongoing call events', () async {
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
    final monologProvider = Get.put(MonologDriftProvider(common, scoped));
    final draftProvider = Get.put(DraftDriftProvider(common, scoped));
    final sessionProvider = Get.put(VersionDriftProvider(common));
    final locksProvider = Get.put(LockDriftProvider(common));
    final secretsProvider = Get.put(RefreshSecretDriftProvider(common));

    await accountProvider.upsert(const UserId('me'));
    await credentialsProvider.upsert(
      Credentials(
        AccessToken(
          const AccessTokenSecret('token'),
          PreciseDateTime.now().add(const Duration(days: 1)),
        ),
        RefreshToken(
          const RefreshTokenSecret('token'),
          PreciseDateTime.now().add(const Duration(days: 1)),
        ),
        Session(
          id: const SessionId('me'),
          ip: IpAddress('localhost'),
          userAgent: UserAgent(''),
          lastActivatedAt: PreciseDateTime.now(),
        ),
        const UserId('me'),
      ),
    );

    final graphQlProvider = _FakeGraphQlProvider(
      initialOngoingCalls: [
        {
          'id': 'first',
          'chatId': 'chatId',
          'author': _caller(),
          'answered': false,
          'at': DateTime.now().toString(),
          'withVideo': false,
          'members': [
            {
              'user': _caller(),
              'handRaised': false,
              'joinedAt': DateTime.now().toString(),
            },
          ],
          'dialed': {
            '__typename': 'ChatMembersDialedAll',
            'answeredMembers': [],
          },
          'ver': '1',
          'presence': 'AWAY',
          'online': {'__typename': 'UserOnline'},
        },
      ],
    );
    Get.put<GraphQlProvider>(graphQlProvider);

    AuthRepository authRepository = Get.put(
      AuthRepository(graphQlProvider, myUserProvider, credentialsProvider),
    );
    AuthService authService = Get.put(
      AuthService(
        authRepository,
        credentialsProvider,
        accountProvider,
        locksProvider,
        secretsProvider,
      ),
    );
    router = RouterState(authService);
    await authService.init();

    UserRepository userRepository = Get.put(
      UserRepository(graphQlProvider, userProvider, me: const UserId('me')),
    );
    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        backgroundProvider,
        callRectProvider,
        me: const UserId('me'),
      ),
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
    ChatRepository chatRepository = Get.put(
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
    CallService callService = Get.put(
      CallService(authService, chatService, callRepository),
    );
    callService.onReady();

    await Future.delayed(Duration.zero);
    expect(callService.calls.length, 1);
    expect(callService.calls.values.first.value.callChatItemId!.val, 'first');

    graphQlProvider.chatEventsStream.add(
      QueryResult.internal(
        source: QueryResultSource.network,
        data: {
          'chatEvents': {
            '__typename': 'ChatEventsVersioned',
            'ver': '1',
            'events': [
              {
                '__typename': 'EventChatCallFinished',
                'chatId': 'chatId',
                'callId': 'first',
                'call': {
                  '__typename': 'ChatCall',
                  'id': 'first',
                  'chatId': 'chatId',
                  'author': _caller(),
                  'answered': false,
                  'at': DateTime.now().toString(),
                  'conversationStartedAt': null,
                  'finishReason': 'UNANSWERED',
                  'finishedAt': DateTime.now().toString(),
                  'joinLink': null,
                  'members': [
                    {
                      'user': _caller(),
                      'handRaised': false,
                      'joinedAt': DateTime.now().toString(),
                    },
                  ],
                  'ver': '1',
                  'withVideo': false,
                  'dialed': {
                    '__typename': 'ChatMembersDialedAll',
                    'answeredMembers': [],
                  },
                },
                'reason': 'UNANSWERED',
                'at': DateTime.now().toString(),
              },
            ],
          },
        },
        parserFn: (_) => null,
      ),
    );

    await Future.delayed(1.seconds);
    expect(callService.calls.length, 0);

    graphQlProvider.ongoingCallStream.add(
      QueryResult.internal(
        source: QueryResultSource.network,
        data: {
          'incomingChatCallsTopEvents': {
            '__typename': 'EventIncomingChatCallsTopChatCallAdded',
            'call': {
              'id': 'second',
              'chatId': 'chatId',
              'author': _caller(),
              'answered': false,
              'at': DateTime.now().toString(),
              'withVideo': false,
              'members': [
                {
                  'user': _caller(),
                  'handRaised': false,
                  'joinedAt': DateTime.now().toString(),
                },
              ],
              'ver': '2',
              'presence': 'AWAY',
              'online': {'__typename': 'UserOnline'},
              'dialed': {
                '__typename': 'ChatMembersDialedAll',
                'answeredMembers': [],
              },
            },
          },
        },
        parserFn: (_) => null,
      ),
    );

    await Future.delayed(Duration.zero);
    expect(callService.calls.length, 1);
    expect(callService.calls.values.first.value.callChatItemId!.val, 'second');

    await Get.deleteAll();
  });

  test('CallService registers and successfully answers the call', () async {
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
    final monologProvider = Get.put(MonologDriftProvider(common, scoped));
    final draftProvider = Get.put(DraftDriftProvider(common, scoped));
    final sessionProvider = Get.put(VersionDriftProvider(common));
    final locksProvider = Get.put(LockDriftProvider(common));
    final secretsProvider = Get.put(RefreshSecretDriftProvider(common));

    final graphQlProvider = _FakeGraphQlProvider();
    Get.put<GraphQlProvider>(graphQlProvider);

    final AuthRepository authRepository = Get.put(
      AuthRepository(graphQlProvider, myUserProvider, credentialsProvider),
    );
    final AuthService authService = Get.put(
      AuthService(
        authRepository,
        credentialsProvider,
        accountProvider,
        locksProvider,
        secretsProvider,
      ),
    );
    router = RouterState(authService);
    await authService.init();

    final UserRepository userRepository = Get.put(
      UserRepository(graphQlProvider, userProvider, me: const UserId('me')),
    );
    final AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        backgroundProvider,
        callRectProvider,
        me: const UserId('me'),
      ),
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
    final ChatRepository chatRepository = Get.put(
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
    final CallService callService = Get.put(
      CallService(authService, chatService, callRepository),
    );
    callService.onReady();

    await Future.delayed(Duration.zero);
    expect(callService.calls.length, 0);

    await callService.call(
      const ChatId('outgoing'),
      withAudio: false,
      withVideo: false,
      withScreen: false,
    );
    expect(callService.calls.length, 1);
    expect(
      callService.calls.values.first.value.state.value,
      OngoingCallState.local,
    );

    await Future.delayed(Duration.zero);
    expect(callService.calls.length, 1);
    expect(callService.calls.values.first.value.chatId.value.val, 'outgoing');
    expect(callService.calls.values.first.value.caller?.id.val, 'me');

    await callService.leave(
      const ChatId('outgoing'),
      const ChatCallDeviceId('device'),
    );

    await Future.delayed(Duration.zero);
    expect(callService.calls.length, 0);

    await Get.deleteAll();
  });

  test('CallService registers and successfully starts the call', () async {
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
    final monologProvider = Get.put(MonologDriftProvider(common, scoped));
    final draftProvider = Get.put(DraftDriftProvider(common, scoped));
    final sessionProvider = Get.put(VersionDriftProvider(common));
    final locksProvider = Get.put(LockDriftProvider(common));
    final secretsProvider = Get.put(RefreshSecretDriftProvider(common));

    final graphQlProvider = _FakeGraphQlProvider();

    AuthRepository authRepository = Get.put(
      AuthRepository(graphQlProvider, myUserProvider, credentialsProvider),
    );
    AuthService authService = Get.put(
      AuthService(
        authRepository,
        credentialsProvider,
        accountProvider,
        locksProvider,
        secretsProvider,
      ),
    );
    router = RouterState(authService);
    await authService.init();

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
    ChatRepository chatRepository = Get.put(
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
    CallService callService = Get.put(
      CallService(authService, chatService, callRepository),
    );
    callService.onReady();

    await Future.delayed(const Duration(milliseconds: 16));
    expect(callService.calls.length, 0);

    graphQlProvider.ongoingCallStream.add(
      QueryResult.internal(
        source: QueryResultSource.network,
        data: {
          'incomingChatCallsTopEvents': {
            '__typename': 'EventIncomingChatCallsTopChatCallAdded',
            'call': {
              'id': 'id',
              'chatId': 'incoming',
              'author': _caller(),
              'answered': false,
              'at': DateTime.now().toString(),
              'withVideo': false,
              'members': [
                {
                  'user': _caller(),
                  'handRaised': false,
                  'joinedAt': DateTime.now().toString(),
                },
              ],
              'ver': '1',
              'presence': 'AWAY',
              'online': {'__typename': 'UserOnline'},
              'dialed': {
                '__typename': 'ChatMembersDialedAll',
                'answeredMembers': [],
              },
            },
          },
        },
        parserFn: (_) => null,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 16));
    expect(callService.calls.length, 1);
    expect(callService.calls.values.first.value.chatId.value.val, 'incoming');

    await callService.decline(const ChatId('incoming'));

    await Future.delayed(const Duration(milliseconds: 16));
    expect(callService.calls.length, 0);
    await Future.delayed(const Duration(milliseconds: 16));

    await Future.delayed(const Duration(seconds: 2));
    graphQlProvider.ongoingCallStream.add(
      QueryResult.internal(
        source: QueryResultSource.network,
        data: {
          'incomingChatCallsTopEvents': {
            '__typename': 'EventIncomingChatCallsTopChatCallAdded',
            'call': {
              'id': 'id1',
              'chatId': 'incoming',
              'author': _caller(),
              'answered': false,
              'at': DateTime.now().toString(),
              'withVideo': false,
              'members': [
                {
                  'user': _caller(),
                  'handRaised': false,
                  'joinedAt': DateTime.now().toString(),
                },
              ],
              'ver': '2',
              'PRESENCE': 'AWAY',
              'online': {'__typename': 'UserOnline'},
              'dialed': {
                '__typename': 'ChatMembersDialedAll',
                'answeredMembers': [],
              },
            },
          },
        },
        parserFn: (_) => null,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 16));
    expect(callService.calls.length, 1);
    expect(callService.calls.values.first.value.chatId.value.val, 'incoming');

    await callService.join(
      const ChatId('incoming'),
      withAudio: true,
      withVideo: false,
      withScreen: false,
    );

    await Future.delayed(const Duration(milliseconds: 16));
    expect(callService.calls.length, 1);

    await Get.deleteAll();
  });

  tearDown(() async => await Future.wait([common.close(), scoped.close()]));
}

class _FakeGraphQlProvider extends MockedGraphQlProvider {
  _FakeGraphQlProvider({this.initialOngoingCalls});

  List<Map<String, dynamic>>? initialOngoingCalls;
  int latestVersion = 0;

  @override
  set authExceptionHandler(_) {}

  @override
  set token(_) {}

  final StreamController<QueryResult> _heartbeat = StreamController.broadcast();

  @override
  InternalFinalCallback<void> get onStart =>
      InternalFinalCallback(callback: () {});

  @override
  InternalFinalCallback<void> get onDelete =>
      InternalFinalCallback(callback: () {});

  @override
  Future<void> reconnect() async {
    // No-op.
  }

  @override
  Stream<QueryResult> callEvents(ChatItemId id, ChatCallDeviceId deviceId) =>
      _heartbeat.stream;

  @override
  Stream<QueryResult> chatEvents(
    ChatId id,
    ChatVersion? ver,
    FutureOr<ChatVersion?> Function() onVer, {
    int priority = 0,
  }) {
    Future.delayed(
      Duration.zero,
      () => chatEventsStream.add(
        QueryResult.internal(
          source: QueryResultSource.network,
          data: {
            'chatEvents': {'__typename': 'SubscriptionInitialized', 'ok': true},
          },
          parserFn: (_) => null,
        ),
      ),
    );
    return chatEventsStream.stream;
  }

  @override
  Stream<QueryResult> incomingCallsTopEvents(int count) {
    ongoingCallStream.add(
      QueryResult.internal(
        source: QueryResultSource.network,
        data: {
          'incomingChatCallsTopEvents': {
            '__typename': 'IncomingChatCallsTop',
            'list': initialOngoingCalls ?? [],
          },
        },
        parserFn: (_) => null,
      ),
    );
    return ongoingCallStream.stream;
  }

  @override
  Stream<QueryResult> recentChatsTopEvents(
    int count, {
    bool noFavorite = false,
    bool archived = false,
    bool? withOngoingCalls,
  }) => Stream.value(
    QueryResult.internal(
      source: QueryResultSource.network,
      data: {
        'recentChatsTopEvents': {
          '__typename': 'SubscriptionInitialized',
          'ok': true,
        },
      },
      parserFn: (_) => null,
    ),
  );

  @override
  Future<Stream<QueryResult>> userEvents(
    UserId id,
    Future<UserVersion?> Function() ver,
  ) async => Stream.value(
    QueryResult.internal(
      source: QueryResultSource.network,
      data: {
        'userEvents': {'__typename': 'SubscriptionInitialized', 'ok': true},
      },
      parserFn: (_) => null,
    ),
  );

  @override
  Future<StartCall$Mutation$StartChatCall$StartChatCallOk> startChatCall(
    ChatId chatId,
    ChatCallCredentials creds, [
    bool? withVideo,
  ]) async {
    latestVersion++;
    ongoingCallStream.add(
      QueryResult.internal(
        source: QueryResultSource.network,
        data: {
          'incomingChatCallsTopEvents': {
            '__typename': 'EventIncomingChatCallsTopChatCallAdded',
            'call': {
              'id': 'id',
              'chatId': chatId.val,
              'author': _caller('me'),
              'answered': false,
              'at': DateTime.now().toString(),
              'withVideo': false,
              'members': [
                {
                  'user': _caller('me'),
                  'handRaised': false,
                  'joinedAt': DateTime.now().toString(),
                },
              ],
              'ver': '$latestVersion',
              'presence': 'AWAY',
              'online': {'__typename': 'UserOnline'},
              'dialed': {
                '__typename': 'ChatMembersDialedAll',
                'answeredMembers': [],
              },
            },
          },
        },
        parserFn: (_) => null,
      ),
    );

    return (StartCall$Mutation.fromJson({
          'startChatCall': {
            '__typename': 'StartChatCallOk',
            'deviceId': 'deviceId',
            'event': {
              '__typename': 'ChatEventsVersioned',
              'events': [
                {
                  '__typename': 'EventChatCallStarted',
                  'callId': 'id',
                  'chatId': chatId.val,
                  'call': {
                    'id': 'id',
                    'chatId': chatId.val,
                    'author': _caller('me'),
                    'answered': false,
                    'at': DateTime.now().toString(),
                    'withVideo': false,
                    'members': [
                      {
                        'user': _caller('me'),
                        'handRaised': false,
                        'joinedAt': DateTime.now().toString(),
                      },
                    ],
                    'ver': '$latestVersion',
                    'presence': 'AWAY',
                    'online': {'__typename': 'UserOnline'},
                    'dialed': {
                      '__typename': 'ChatMembersDialedAll',
                      'answeredMembers': [],
                    },
                  },
                },
              ],
              'ver': '$latestVersion',
            },
          },
        }).startChatCall
        as StartCall$Mutation$StartChatCall$StartChatCallOk);
  }

  @override
  Future<RecentChats$Query> recentChats({
    int? first,
    RecentChatsCursor? after,
    int? last,
    RecentChatsCursor? before,
    bool noFavorite = false,
    bool archived = false,
    bool? withOngoingCalls,
  }) async {
    return RecentChats$Query.fromJson(chatsQuery);
  }

  @override
  Future<FavoriteChats$Query> favoriteChats({
    int? first,
    FavoriteChatsCursor? after,
    int? last,
    FavoriteChatsCursor? before,
  }) async {
    return FavoriteChats$Query.fromJson(favoriteQuery);
  }

  @override
  Future<ChatEventsVersionedMixin?> leaveChatCall(
    ChatId chatId,
    ChatCallDeviceId deviceId,
  ) async {
    chatEventsStream.add(
      QueryResult.internal(
        source: QueryResultSource.network,
        data: {
          'chatEvents': {
            '__typename': 'ChatEventsVersioned',
            'ver': '1',
            'events': [
              {
                '__typename': 'EventChatCallFinished',
                'chatId': chatId.val,
                'callId': 'id',
                'call': {
                  '__typename': 'ChatCall',
                  'id': 'id',
                  'chatId': chatId.val,
                  'author': _caller('me'),
                  'answered': false,
                  'at': DateTime.now().toString(),
                  'conversationStartedAt': null,
                  'finishReason': 'UNANSWERED',
                  'finishedAt': DateTime.now().toString(),
                  'joinLink': null,
                  'members': [
                    {
                      'user': _caller('me'),
                      'handRaised': false,
                      'joinedAt': DateTime.now().toString(),
                    },
                  ],
                  'ver': '1',
                  'withVideo': false,
                },
                'reason': 'DROPPED',
                'at': DateTime.now().toString(),
              },
            ],
          },
        },
        parserFn: (_) => null,
      ),
    );

    return null;
  }

  @override
  Future<ChatEventsVersionedMixin?> declineChatCall(ChatId chatId) async =>
      leaveChatCall(chatId, const ChatCallDeviceId(''));

  @override
  Future<JoinCall$Mutation$JoinChatCall$JoinChatCallOk> joinChatCall(
    ChatId chatId,
    ChatCallCredentials creds,
  ) async =>
      (JoinCall$Mutation.fromJson({
            'joinChatCall': {
              '__typename': 'JoinChatCallOk',
              'deviceId': 'deviceId',
              'event': {
                '__typename': 'ChatEventsVersioned',
                'events': [
                  {
                    '__typename': 'EventChatCallMemberJoined',
                    'callId': 'id',
                    'chatId': chatId.val,
                    'call': {
                      'id': 'id',
                      'chatId': chatId.val,
                      'author': _caller('me'),
                      'answered': false,
                      'at': DateTime.now().toString(),
                      'withVideo': false,
                      'members': [
                        {
                          'user': _caller('me'),
                          'handRaised': false,
                          'joinedAt': DateTime.now().toString(),
                        },
                      ],
                      'ver': '$latestVersion',
                      'presence': 'AWAY',
                      'online': {'__typename': 'UserOnline'},
                    },
                    'user': _caller('me'),
                    'at': DateTime.now().toString(),
                  },
                ],
                'ver': '$latestVersion',
              },
            },
          }).joinChatCall
          as JoinCall$Mutation$JoinChatCall$JoinChatCallOk);

  @override
  Future<GetChat$Query> getChat(ChatId id) async {
    return GetChat$Query.fromJson({'chat': chatData});
  }

  Map<String, dynamic> userData = {
    'id': 'id',
    'num': '1234567890123456',
    'login': null,
    'name': null,
    'emails': {'confirmed': []},
    'phones': {'confirmed': []},
    'chatDirectLink': null,
    'hasPassword': false,
    'unreadChatsCount': 0,
    'ver': '30066501444801094020394372057490153134',
    'presence': 'AWAY',
    'online': {'__typename': 'UserOnline'},
  };

  @override
  Future<ChatMixin?> getMonolog() async {
    return GetMonolog$Query.fromJson({'monolog': null}).monolog;
  }

  @override
  Future<UserMixin?> getUser(UserId id) async {
    return GetUser$Query.fromJson({'user': null}).user;
  }

  @override
  Future<GetMessage$Query> chatItem(ChatItemId id) async {
    return GetMessage$Query.fromJson({'chatItem': null});
  }

  @override
  Future<ChatMixin?> getDialog(UserId userId) => Future.value(null);
}

Map<String, dynamic> _caller([String? id]) => {
  'id': id ?? 'id',
  'num': '1234567890123456',
  'mutualContactsCount': 0,
  'contacts': [],
  'isDeleted': false,
  'isBlocked': {'ver': '0'},
  'presence': 'AWAY',
  'ver': '0',
};

final chatData = {
  'id': 'chatId',
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

final chatsQuery = {
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

final favoriteQuery = {
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

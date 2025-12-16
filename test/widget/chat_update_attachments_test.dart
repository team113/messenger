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

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/domain/service/notification.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/provider/drift/account.dart';
import 'package:messenger/provider/drift/background.dart';
import 'package:messenger/provider/drift/blocklist.dart';
import 'package:messenger/provider/drift/cache.dart';
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
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/blocklist.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/contact.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';
import 'package:messenger/ui/worker/cache.dart';
import 'package:messenger/util/audio_utils.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/audio_utils.dart';
import '../mock/platform_utils.dart';
import 'chat_update_attachments_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GraphQlProvider>(),
  MockSpec<PlatformRouteInformationProvider>(),
])
void main() async {
  PlatformUtils = PlatformUtilsMock(cache: null);
  AudioUtils = AudioUtilsMock();

  final dio = Dio(BaseOptions());
  final dioAdapter = DioAdapter(dio: dio);
  PlatformUtils.client = dio;

  dioAdapter.onGet('oldRef.png', (server) {
    server.reply(
      200,
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );
  });

  dioAdapter.onGet('updatedRef.png', (server) {
    server.reply(
      200,
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  Config.files = '';
  Config.disableDragArea = true;

  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(
    graphQlProvider.onStart,
  ).thenReturn(InternalFinalCallback(callback: () {}));
  when(
    graphQlProvider.onDelete,
  ).thenReturn(InternalFinalCallback(callback: () {}));
  when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());
  Get.put<GraphQlProvider>(graphQlProvider);

  when(graphQlProvider.recentChatsTopEvents(3)).thenAnswer(
    (_) => Stream.value(
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
    ),
  );
  when(
    graphQlProvider.recentChatsTopEvents(3, archived: true),
  ).thenAnswer((_) => const Stream.empty());

  when(
    graphQlProvider.chatEvents(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      any,
      any,
    ),
  ).thenAnswer((_) => const Stream.empty());

  when(
    graphQlProvider.getChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    ),
  ).thenAnswer((_) => Future.value(GetChat$Query.fromJson({'chat': chatData})));

  when(
    graphQlProvider.readChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      const ChatItemId('6d1c8e23-8583-4e3d-9ebb-413c95c786b0'),
    ),
  ).thenAnswer((_) => Future.value(null));

  when(
    graphQlProvider.chatItems(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      last: 50,
    ),
  ).thenAnswer(
    (_) => Future.value(
      GetMessages$Query.fromJson({
        'chat': {
          'items': {
            'edges': [
              {
                'node': {
                  '__typename': 'ChatMessage',
                  'id': '6d1c8e23-8583-4e3d-9ebb-413c95c786b0',
                  'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                  'author': {
                    'id': 'me',
                    'num': '1234567890123456',
                    'mutualContactsCount': 0,
                    'contacts': [],
                    'isDeleted': false,
                    'isBlocked': {'ver': '0'},
                    'presence': 'AWAY',
                    'ver': '0',
                  },
                  'at': '2022-02-01T09:32:52.246988+00:00',
                  'ver': '10',
                  'repliesTo': [],
                  'text': null,
                  'editedAt': null,
                  'attachments': [
                    {
                      '__typename': 'ImageAttachment',
                      'id': 'c7f4b137-28b2-40aa-824f-891387e3c0b5',
                      'filename': 'filename.png',
                      'original': {
                        'relativeRef': 'oldRef.png',
                        'checksum': 'oldChecksum1',
                      },
                      'big': {
                        'relativeRef': 'oldRef.png',
                        'checksum': 'oldChecksum2',
                      },
                      'medium': {
                        'relativeRef': 'oldRef.png',
                        'checksum': 'oldChecksum3',
                      },
                      'small': {
                        'relativeRef': 'oldRef.png',
                        'checksum': 'oldChecksum4',
                      },
                    },
                  ],
                },
                'cursor': '123',
              },
            ],
            'pageInfo': {
              'endCursor': 'endCursor',
              'hasNextPage': false,
              'startCursor': 'startCursor',
              'hasPreviousPage': false,
            },
          },
        },
      }),
    ),
  );

  when(graphQlProvider.chatItem(any)).thenAnswer(
    (_) => Future.value(GetMessage$Query.fromJson({'chatItem': null})),
  );

  when(graphQlProvider.attachments(any)).thenAnswer(
    (_) => Future.value(
      GetAttachments$Query.fromJson({
        'chatItem': {
          'node': {
            '__typename': 'ChatMessage',
            'repliesTo': [],
            'attachments': [
              {
                '__typename': 'ImageAttachment',
                'id': 'c7f4b137-28b2-40aa-824f-891387e3c0b5',
                'filename': 'filename.png',
                'original': {
                  'relativeRef': 'updatedRef.png',
                  'checksum': 'updatedChecksum1',
                },
                'big': {
                  'relativeRef': 'updatedRef.png',
                  'checksum': 'updatedChecksum2',
                },
                'medium': {
                  'relativeRef': 'updatedRef.png',
                  'checksum': 'updatedChecksum3',
                },
                'small': {
                  'relativeRef': 'updatedRef.png',
                  'checksum': 'updatedChecksum4',
                },
              },
            ],
          },
        },
      }),
    ),
  );

  when(
    graphQlProvider.recentChats(
      first: anyNamed('first'),
      after: null,
      last: null,
      before: null,
      noFavorite: anyNamed('noFavorite'),
      archived: anyNamed('archived'),
      withOngoingCalls: anyNamed('withOngoingCalls'),
    ),
  ).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

  when(
    graphQlProvider.favoriteChats(
      first: anyNamed('first'),
      after: null,
      last: null,
      before: null,
    ),
  ).thenAnswer(
    (_) => Future.value(FavoriteChats$Query.fromJson(favoriteChats)),
  );

  when(
    graphQlProvider.chatMembers(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      first: anyNamed('first'),
    ),
  ).thenAnswer(
    (_) => Future.value(
      GetMembers$Query.fromJson({
        'chat': {
          'members': {
            'edges': [],
            'pageInfo': {
              'endCursor': 'endCursor',
              'hasNextPage': false,
              'startCursor': 'startCursor',
              'hasPreviousPage': false,
            },
          },
        },
      }),
    ),
  );

  when(graphQlProvider.incomingCalls()).thenAnswer(
    (_) => Future.value(
      IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []}),
    ),
  );
  when(
    graphQlProvider.incomingCallsTopEvents(3),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.favoriteChatsEvents(any),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.myUserEvents(any),
  ).thenAnswer((_) async => const Stream.empty());
  when(
    graphQlProvider.sessionsEvents(any),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.blocklistEvents(any),
  ).thenAnswer((_) => const Stream.empty());
  when(
    graphQlProvider.getUser(any),
  ).thenAnswer((_) => Future.value(GetUser$Query.fromJson({'user': null})));
  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  when(
    graphQlProvider.getBlocklist(
      first: anyNamed('first'),
      after: null,
      last: null,
      before: null,
    ),
  ).thenAnswer(
    (_) => Future.value(GetBlocklist$Query$Blocklist.fromJson(blacklist)),
  );

  final credentialsProvider = Get.put(CredentialsDriftProvider(common));
  final accountProvider = Get.put(AccountDriftProvider(common));

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

  final settingsProvider = Get.put(SettingsDriftProvider(common));
  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final userProvider = Get.put(UserDriftProvider(common, scoped));
  final chatItemProvider = Get.put(ChatItemDriftProvider(common, scoped));
  final chatMemberProvider = Get.put(ChatMemberDriftProvider(common, scoped));
  final chatProvider = Get.put(ChatDriftProvider(common, scoped));
  final backgroundProvider = Get.put(BackgroundDriftProvider(common));
  final blocklistProvider = Get.put(BlocklistDriftProvider(common, scoped));
  final cacheProvider = CacheDriftProvider(common);
  final callCredentialsProvider = Get.put(
    CallCredentialsDriftProvider(common, scoped),
  );
  final chatCredentialsProvider = Get.put(
    ChatCredentialsDriftProvider(common, scoped),
  );
  final callRectProvider = Get.put(CallRectDriftProvider(common, scoped));
  final draftProvider = Get.put(DraftDriftProvider(common, scoped));
  final monologProvider = Get.put(MonologDriftProvider(common, scoped));
  final versionProvider = Get.put(VersionDriftProvider(common));
  final locksProvider = Get.put(LockDriftProvider(common));

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      theme: Themes.light(),
      home: Builder(
        builder: (BuildContext context) {
          router.context = context;
          return Scaffold(body: child);
        },
      ),
    );
  }

  testWidgets('ChatView successfully refreshes image attachments', (
    WidgetTester tester,
  ) async {
    final StreamController<QueryResult> contactEvents = StreamController();
    when(
      graphQlProvider.contactsEvents(any),
    ).thenAnswer((_) => contactEvents.stream);

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(
          AuthRepository(Get.find(), myUserProvider, credentialsProvider),
        ),
        credentialsProvider,
        accountProvider,
        locksProvider,
      ),
    );

    router = RouterState(authService);
    router.provider = MockPlatformRouteInformationProvider();

    authService.init();

    UserRepository userRepository = Get.put(
      UserRepository(graphQlProvider, userProvider),
    );
    BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
        graphQlProvider,
        blocklistProvider,
        userRepository,
        versionProvider,
        me: const UserId('me'),
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

    final callRepository = CallRepository(
      graphQlProvider,
      userRepository,
      callCredentialsProvider,
      chatCredentialsProvider,
      settingsRepository,
      me: const UserId('me'),
    );

    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        chatProvider,
        chatItemProvider,
        chatMemberProvider,
        callRepository,
        draftProvider,
        userRepository,
        versionProvider,
        monologProvider,
        me: const UserId('me'),
      ),
    );

    final contactRepository = Get.put(
      ContactRepository(
        graphQlProvider,
        userRepository,
        versionProvider,
        me: const UserId('me'),
      ),
    );

    Get.put(
      MyUserService(
        authService,
        Get.put(
          MyUserRepository(
            graphQlProvider,
            myUserProvider,
            blocklistRepository,
            userRepository,
            accountProvider,
          ),
        ),
      ),
    );

    Get.put(UserService(userRepository));
    ChatService chatService = Get.put(ChatService(chatRepository, authService));
    Get.put(CallService(authService, chatService, callRepository));

    Get.put(CacheWorker(cacheProvider, null));

    Get.put(ContactService(contactRepository));
    Get.put(NotificationService(graphQlProvider));

    await tester.pumpWidget(
      createWidgetForTesting(
        child: const ChatView(ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')),
      ),
    );

    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.runAsync(() => Future.delayed(1.milliseconds));
    }

    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      find.byKey(const Key('Image_oldRef.png'), skipOffstage: false).first,
      findsOneWidget,
    );

    await tester.runAsync(() => Future.delayed(1.seconds));

    final RxChat chat = chatRepository
        .chats[const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')]!;
    await tester.runAsync(
      () => chat.updateAttachments(chat.messages.first.value),
    );

    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.runAsync(() => Future.delayed(1.milliseconds));
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      find.byKey(const Key('Image_updatedRef.png'), skipOffstage: false).first,
      findsOneWidget,
    );

    await tester.pumpAndSettle(const Duration(seconds: 2));

    common.close();
    scoped.close();

    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.runAsync(() => Future.delayed(1.milliseconds));
    }

    await Get.deleteAll(force: true);
  });
}

final chatData = {
  'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
  'name': 'startname',
  'avatar': null,
  'members': {'nodes': [], 'totalCount': 0},
  'kind': 'GROUP',
  'isHidden': false,
  'isArchived': false,
  'muted': null,
  'directLink': null,
  'createdAt': '2021-12-15T15:11:18.316846+00:00',
  'updatedAt': '2021-12-15T15:11:18.316846+00:00',
  'lastReads': [
    {'memberId': 'me', 'at': '2022-01-01T07:27:30.151628+00:00'},
  ],
  'lastDelivery': '1970-01-01T00:00:00+00:00',
  'lastItem': null,
  'lastReadItem': null,
  'unreadCount': 0,
  'totalCount': 0,
  'ongoingCall': null,
  'ver': '0',
};

final recentChats = {
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

final favoriteChats = {
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

final chatContacts = {
  'chatContacts': {
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

final favoriteChatContacts = {
  'favoriteChatContacts': {
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

final blacklist = {
  'edges': [],
  'pageInfo': {
    'endCursor': 'endCursor',
    'hasNextPage': false,
    'startCursor': 'startCursor',
    'hasPreviousPage': false,
  },
};

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
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
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
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/blocklist.dart';
import 'package:messenger/provider/hive/blocklist_sorting.dart';
import 'package:messenger/provider/hive/call_credentials.dart';
import 'package:messenger/provider/hive/call_rect.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_credentials.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/contact_sorting.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/favorite_chat.dart';
import 'package:messenger/provider/hive/favorite_contact.dart';
import 'package:messenger/provider/hive/session_data.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/monolog.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/recent_chat.dart';
import 'package:messenger/provider/hive/credentials.dart';
import 'package:messenger/provider/hive/user.dart';
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
import 'package:messenger/ui/page/home/page/chat/view.dart';
import 'package:messenger/util/audio_utils.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/audio_utils.dart';
import '../mock/platform_utils.dart';
import 'chat_reply_message_test.mocks.dart';
import 'extension/rich_text.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  PlatformUtils = PlatformUtilsMock();
  TestWidgetsFlutterBinding.ensureInitialized();
  AudioUtils = AudioUtilsMock();
  Hive.init('./test/.temp_hive/chat_reply_message_widget');

  var userData = {
    'id': 'me',
    'num': '1234567890123456',
    'login': 'login',
    'name': 'name',
    'emails': {'confirmed': [], 'unconfirmed': null},
    'phones': {'confirmed': [], 'unconfirmed': null},
    'hasPassword': true,
    'unreadChatsCount': 0,
    'ver': '0',
    'online': {'__typename': 'UserOnline'},
    'presence': 'AWAY',
  };

  var chatData = {
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
    'name': 'startname',
    'avatar': null,
    'members': {'nodes': [], 'totalCount': 0},
    'kind': 'GROUP',
    'isHidden': false,
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
    'ver': '0'
  };

  var recentChats = {
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

  var favoriteChats = {
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

  var chatContacts = {
    'chatContacts': {
      'edges': [],
      'pageInfo': {
        'endCursor': 'endCursor',
        'hasNextPage': false,
        'startCursor': 'startCursor',
        'hasPreviousPage': false,
      },
      'ver': '0',
    }
  };

  var favoriteChatContacts = {
    'favoriteChatContacts': {
      'edges': [],
      'pageInfo': {
        'endCursor': 'endCursor',
        'hasNextPage': false,
        'startCursor': 'startCursor',
        'hasPreviousPage': false,
      },
      'ver': '0',
    }
  };

  var blacklist = {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    }
  };

  var graphQlProvider = MockGraphQlProvider();
  Get.put<GraphQlProvider>(graphQlProvider);
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  when(graphQlProvider.getUser(const UserId('me')))
      .thenAnswer((_) => Future.value(GetUser$Query.fromJson(userData)));

  when(graphQlProvider.recentChatsTopEvents(3)).thenAnswer((_) => Stream.value(
        QueryResult.internal(
          source: QueryResultSource.network,
          data: {
            'recentChatsTopEvents': {
              '__typename': 'SubscriptionInitialized',
              'ok': true
            }
          },
          parserFn: (_) => null,
        ),
      ));

  final StreamController<QueryResult> contactEvents = StreamController();
  when(
    graphQlProvider.contactsEvents(any),
  ).thenAnswer((_) => contactEvents.stream);

  when(graphQlProvider.favoriteChatContacts(
    first: anyNamed('first'),
    before: null,
    after: null,
    last: null,
  )).thenAnswer(
    (_) => Future.value(FavoriteContacts$Query.fromJson(favoriteChatContacts)
        .favoriteChatContacts),
  );

  when(graphQlProvider.chatContacts(
    first: anyNamed('first'),
    noFavorite: true,
    before: null,
    after: null,
    last: null,
  )).thenAnswer(
      (_) => Future.value(Contacts$Query.fromJson(chatContacts).chatContacts));

  final StreamController<QueryResult> chatEvents = StreamController();
  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    any,
    any,
  )).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider
          .keepTyping(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider
          .getChat(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')))
      .thenAnswer(
          (_) => Future.value(GetChat$Query.fromJson({'chat': chatData})));

  when(graphQlProvider.readChat(
          const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          const ChatItemId('91e6e597-e6ca-4b1f-ad70-83dd621e4cb4')))
      .thenAnswer((_) => Future.value(null));

  when(graphQlProvider.readChat(
          const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          const ChatItemId('145f6006-82b9-4d07-9229-354146e4f332')))
      .thenAnswer((_) => Future.value(null));

  when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.chatItems(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    last: 50,
  )).thenAnswer((_) => Future.value(GetMessages$Query.fromJson({
        'chat': {
          'items': {
            'edges': [
              {
                'node': {
                  '__typename': 'ChatMessage',
                  'id': '91e6e597-e6ca-4b1f-ad70-83dd621e4cb4',
                  'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                  'author': {
                    'id': 'me',
                    'num': '1234567890123456',
                    'mutualContactsCount': 0,
                    'isDeleted': false,
                    'isBlocked': {'ver': '0'},
                    'presence': 'AWAY',
                    'ver': '0',
                  },
                  'at': '2022-01-05T15:40:57.010950+00:00',
                  'ver': '1',
                  'repliesTo': [],
                  'text': 'text message',
                  'editedAt': null,
                  'attachments': []
                },
                'cursor': 'IjkxZTZlNTk3LWU2Y2EtNGIxZi1hZDcwLTgzZGQ2MjFlNGNiNCI='
              },
            ],
            'pageInfo': {
              'endCursor': 'endCursor',
              'hasNextPage': false,
              'startCursor': 'startCursor',
              'hasPreviousPage': false,
            }
          }
        }
      })));

  when(graphQlProvider.chatItem(any)).thenAnswer(
    (_) => Future.value(GetMessage$Query.fromJson({'chatItem': null})),
  );

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
      (_) => Future.value(FavoriteChats$Query.fromJson(favoriteChats)));

  when(graphQlProvider.postChatMessage(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    text: const ChatMessageText('reply message'),
    attachments: anyNamed('attachments'),
    repliesTo: [],
  )).thenAnswer((_) {
    var event = {
      '__typename': 'ChatEventsVersioned',
      'events': [
        {
          '__typename': 'EventChatItemPosted',
          'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
          'item': {
            'node': {
              '__typename': 'ChatMessage',
              'id': '145f6006-82b9-4d07-9229-354146e4f332',
              'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
              'author': {
                'id': 'me',
                'num': '1234567890123456',
                'mutualContactsCount': 0,
                'isDeleted': false,
                'isBlocked': {'ver': '0'},
                'presence': 'AWAY',
                'ver': '0',
              },
              'at': '2022-01-27T11:34:37.191440+00:00',
              'ver': '1',
              'repliesTo': [
                {
                  '__typename': 'ChatMessageQuote',
                  'author': {
                    'id': 'me',
                    'num': '1234567890123456',
                    'mutualContactsCount': 0,
                    'isDeleted': false,
                    'isBlocked': {'ver': '0'},
                    'presence': 'AWAY',
                    'ver': '0',
                  },
                  'at': '2022-01-27T10:53:21.405546+00:00',
                  'text': '123',
                  'attachments': [],
                },
              ],
              'text': 'reply message',
              'editedAt': null,
              'attachments': []
            },
            'cursor': '123'
          },
        }
      ],
      'ver': '1'
    };

    chatEvents.add(QueryResult.internal(
      data: {'chatEvents': event},
      parserFn: (_) => null,
      source: null,
    ));

    return Future.value(
        PostChatMessage$Mutation.fromJson({'postChatMessage': event})
                .postChatMessage
            as PostChatMessage$Mutation$PostChatMessage$ChatEventsVersioned);
  });

  when(graphQlProvider.incomingCalls()).thenAnswer((_) => Future.value(
      IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []})));
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.favoriteChatsEvents(any))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.myUserEvents(any))
      .thenAnswer((realInvocation) => const Stream.empty());

  when(graphQlProvider.getBlocklist(
    first: anyNamed('first'),
    after: null,
    last: null,
    before: null,
  )).thenAnswer(
    (_) => Future.value(GetBlocklist$Query$Blocklist.fromJson(blacklist)),
  );

  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  when(graphQlProvider.chatMembers(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    first: anyNamed('first'),
  )).thenAnswer((_) => Future.value(GetMembers$Query.fromJson({
        'chat': {
          'members': {
            'edges': [],
            'pageInfo': {
              'endCursor': 'endCursor',
              'hasNextPage': false,
              'startCursor': 'startCursor',
              'hasPreviousPage': false,
            }
          }
        }
      })));

  var credentialsProvider = Get.put(CredentialsHiveProvider());
  await credentialsProvider.init();
  await credentialsProvider.clear();
  credentialsProvider.set(
    Credentials(
      Session(
        const AccessToken('token'),
        PreciseDateTime.now().add(const Duration(days: 1)),
      ),
      RememberedSession(
        const RefreshToken('token'),
        PreciseDateTime.now().add(const Duration(days: 1)),
      ),
      const UserId('me'),
    ),
  );

  AuthService authService =
      AuthService(AuthRepository(graphQlProvider), credentialsProvider);

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

  var contactProvider = Get.put(ContactHiveProvider());
  await contactProvider.init();
  await contactProvider.clear();
  var userProvider = Get.put(UserHiveProvider());
  await userProvider.init();
  await userProvider.clear();
  var chatProvider = Get.put(ChatHiveProvider());
  await chatProvider.init();
  await chatProvider.clear();
  var settingsProvider = MediaSettingsHiveProvider();
  await settingsProvider.init();
  await settingsProvider.clear();
  var draftProvider = Get.put(DraftHiveProvider());
  await draftProvider.init();
  await draftProvider.clear();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  final callCredentialsProvider = CallCredentialsHiveProvider();
  await callCredentialsProvider.init();
  final chatCredentialsProvider = ChatCredentialsHiveProvider();
  await chatCredentialsProvider.init();
  var callRectProvider = CallRectHiveProvider();
  await callRectProvider.init();
  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  await myUserProvider.clear();
  var blockedUsersProvider = BlocklistHiveProvider();
  await blockedUsersProvider.init();
  var monologProvider = MonologHiveProvider();
  await monologProvider.init();
  var recentChatProvider = RecentChatHiveProvider();
  await recentChatProvider.init();
  var favoriteChatProvider = FavoriteChatHiveProvider();
  await favoriteChatProvider.init();
  var sessionProvider = SessionDataHiveProvider();
  await sessionProvider.init();
  var favoriteContactHiveProvider = Get.put(FavoriteContactHiveProvider());
  await favoriteContactHiveProvider.init();
  var contactSortingHiveProvider = Get.put(ContactSortingHiveProvider());
  await contactSortingHiveProvider.init();
  var blocklistSortingProvider = BlocklistSortingHiveProvider();
  await blocklistSortingProvider.init();

  var messagesProvider = Get.put(ChatItemHiveProvider(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
  ));
  await messagesProvider.init(userId: const UserId('me'));
  await messagesProvider.clear();

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
        theme: Themes.light(),
        home: Builder(
          builder: (BuildContext context) {
            router.context = context;
            return Scaffold(body: child);
          },
        ));
  }

  testWidgets('ChatView successfully replies to a message',
      (WidgetTester tester) async {
    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        credentialsProvider,
      ),
    );
    authService.init();

    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));
    BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
        graphQlProvider,
        blockedUsersProvider,
        blocklistSortingProvider,
        userRepository,
        sessionProvider,
      ),
    );
    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        applicationSettingsProvider,
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
        recentChatProvider,
        favoriteChatProvider,
        callRepository,
        draftProvider,
        userRepository,
        sessionProvider,
        monologProvider,
        me: const UserId('me'),
      ),
    );

    final contactRepository = Get.put(
      ContactRepository(
        graphQlProvider,
        contactProvider,
        favoriteContactHiveProvider,
        contactSortingHiveProvider,
        userRepository,
        sessionProvider,
      ),
    );
    Get.put(ContactService(contactRepository));

    MyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      blocklistRepository,
      userRepository,
    );
    Get.put(MyUserService(authService, myUserRepository));

    Get.put(UserService(userRepository));
    ChatService chatService = Get.put(ChatService(chatRepository, authService));
    Get.put(CallService(authService, chatService, callRepository));

    await tester.pumpWidget(createWidgetForTesting(
      child: const ChatView(ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')),
    ));

    // TODO: This waits for lazy [Hive] boxes to finish receiving events, which
    //       should be done in a more strict way.
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.runAsync(() => Future.delayed(1.milliseconds));
    }

    await tester.pumpAndSettle(const Duration(seconds: 2));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await tester.pumpAndSettle(const Duration(seconds: 2));

    var message = find.richText('text message', skipOffstage: false);
    expect(message, findsOneWidget);

    await tester.longPress(message);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('ReplyButton')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await gesture.moveTo(tester.getCenter(find.byKey(const Key('Reply_0'))));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('CancelReplyButton')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.longPress(message);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.enterText(
        find.byKey(const Key('MessageField')), 'reply message');
    await tester.pumpAndSettle(const Duration(seconds: 10));

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.richText('reply message', skipOffstage: false), findsOneWidget);

    await Get.deleteAll(force: true);

    await tester.runAsync(() => Future.delayed(1.milliseconds));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}

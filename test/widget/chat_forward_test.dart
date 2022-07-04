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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/call.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/model/chat.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/view.dart';
import 'package:messenger/ui/widget/context_menu/overlay.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/overflow_error.dart';
import 'chat_forward_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/chat_forward_widget');

  var userData = {
    'id': '0d72d245-8425-467a-9ebd-082d4f47850a',
    'num': '1234567890123456',
    'login': 'login',
    'name': 'name',
    'bio': 'bio',
    'emails': {'confirmed': [], 'unconfirmed': null},
    'phones': <String, dynamic>{'confirmed': [], 'unconfirmed': null},
    'gallery': {'nodes': []},
    'hasPassword': true,
    'unreadChatsCount': 0,
    'ver': '0',
    'presence': 'AWAY',
    'online': {'__typename': 'UserOnline'},
  };

  var chatData = {
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
    'name': 'startname',
    'avatar': null,
    'members': {'nodes': []},
    'kind': 'GROUP',
    'isHidden': false,
    'muted': null,
    'directLink': null,
    'createdAt': '2021-12-15T15:11:18.316846+00:00',
    'updatedAt': '2021-12-15T15:11:18.316846+00:00',
    'lastReads': [
      {
        'memberId': '0d72d245-8425-467a-9ebd-082d4f47850a',
        'at': '2022-01-01T07:27:30.151628+00:00'
      },
    ],
    'lastDelivery': '1970-01-01T00:00:00+00:00',
    'lastItem': null,
    'lastReadItem': null,
    'gallery': {'nodes': []},
    'unreadCount': 0,
    'totalCount': 0,
    'currentCall': null,
    'ver': '0'
  };

  var chatData2 = {
    'id': '0d72d245-8425-467a-9ebd-082d4f47850c',
    'name': 'chat 2',
    'avatar': null,
    'members': {'nodes': []},
    'kind': 'GROUP',
    'isHidden': false,
    'muted': null,
    'directLink': null,
    'createdAt': '2021-12-15T15:11:18.316846+00:00',
    'updatedAt': '2021-12-15T15:11:18.316846+00:00',
    'lastReads': [
      {
        'memberId': '0d72d245-8425-467a-9ebd-082d4f47850a',
        'at': '2022-01-01T07:27:30.151628+00:00'
      },
    ],
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
      'nodes': [chatData, chatData2]
    }
  };

  var graphQlProvider = Get.put<GraphQlProvider>(MockGraphQlProvider());
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  final StreamController<QueryResult> chatEvents = StreamController();
  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    ChatVersion('0'),
  )).thenAnswer((_) => Future.value(chatEvents.stream));

  final StreamController<QueryResult> chatEvents2 = StreamController();
  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850c'),
    ChatVersion('0'),
  )).thenAnswer((_) => Future.value(chatEvents2.stream));

  when(graphQlProvider
          .keepTyping(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  when(graphQlProvider.myUserEvents(null)).thenAnswer(
    (_) => Future.value(Stream.fromIterable([
      QueryResult.internal(
        parserFn: (_) => null,
        source: null,
        data: {
          'myUserEvents': {'__typename': 'MyUser', ...userData},
        },
      ),
    ])),
  );

  when(graphQlProvider
          .getChat(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')))
      .thenAnswer((_) => Future.value(GetChat$Query.fromJson(chatData)));

  when(graphQlProvider.readChat(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    const ChatItemId('91e6e597-e6ca-4b1f-ad70-83dd621e4cb4'),
  )).thenAnswer((_) => Future.value(null));

  when(graphQlProvider.chatItems(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    first: 120,
  )).thenAnswer((_) => Future.value(GetMessages$Query.fromJson({
        'chat': {
          'items': {
            'edges': [
              {
                'node': {
                  '__typename': 'ChatMessage',
                  'id': '91e6e597-e6ca-4b1f-ad70-83dd621e4cb4',
                  'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                  'authorId': '0d72d245-8425-467a-9ebd-082d4f47850a',
                  'at': '2022-01-05T15:40:57.010950+00:00',
                  'ver': '1',
                  'repliesTo': null,
                  'text': 'text message',
                  'editedAt': null,
                  'attachments': []
                },
                'cursor': 'IjkxZTZlNTk3LWU2Y2EtNGIxZi1hZDcwLTgzZGQ2MjFlNGNiNCI='
              },
            ]
          }
        }
      })));

  when(graphQlProvider.recentChats(
    first: 120,
    after: null,
    last: null,
    before: null,
  )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

  when(graphQlProvider.forwardChatItems(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    [
      ChatItemQuoteInput(
        id: const ChatItemId('91e6e597-e6ca-4b1f-ad70-83dd621e4cb4'),
        attachments: [],
        withText: true,
      ),
    ],
  )).thenAnswer((_) {
    var event = {
      '__typename': 'ChatEventsVersioned',
      'events': [
        {
          '__typename': 'EventChatItemPosted',
          'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
          'item': {
            'node': {
              '__typename': 'ChatForward',
              'id': '2fa522d4-47b7-49de-ad34-7a932a312d95',
              'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
              'authorId': '0d72d245-8425-467a-9ebd-082d4f47850a',
              'at': '2022-04-27T16:41:38.461547384+00:00',
              'ver': '0',
              'item': {
                'node': {
                  '__typename': 'ChatMessage',
                  'id': '91e6e597-e6ca-4b1f-ad70-83dd621e4cb4',
                  'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                  'authorId': '0d72d245-8425-467a-9ebd-082d4f47850a',
                  'at': '2022-01-05T15:40:57.010950+00:00',
                  'ver': '1',
                  'repliesTo': null,
                  'text': 'forwarded message',
                  'editedAt': null,
                  'attachments': []
                },
                'cursor': ''
              }
            },
            'cursor': ''
          }
        }
      ],
      'ver': '2'
    };

    chatEvents.add(QueryResult.internal(
      data: {'chatEvents': event},
      parserFn: (_) => null,
      source: null,
    ));

    return Future.value(
        ForwardChatItems$Mutation.fromJson({'forwardChatItems': event})
                .forwardChatItems
            as ForwardChatItems$Mutation$ForwardChatItems$ChatEventsVersioned);
  });

  when(graphQlProvider.forwardChatItems(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    [
      ChatItemQuoteInput(
        id: const ChatItemId('2fa522d4-47b7-49de-ad34-7a932a312d95'),
        attachments: [],
        withText: true,
      ),
    ],
  )).thenAnswer((_) {
    var event = {
      '__typename': 'ChatEventsVersioned',
      'events': [
        {
          '__typename': 'EventChatItemPosted',
          'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
          'item': {
            'node': {
              '__typename': 'ChatForward',
              'id': '2fa522d4-47b7-49de-ad34-7a932a312d96',
              'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
              'authorId': '0d72d245-8425-467a-9ebd-082d4f47850a',
              'at': '2022-04-27T16:41:38.461547384+00:00',
              'ver': '3',
              'item': {
                'node': {
                  '__typename': 'ChatMessage',
                  'id': '91e6e597-e6ca-4b1f-ad70-83dd621e4cb4',
                  'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                  'authorId': '0d72d245-8425-467a-9ebd-082d4f47850a',
                  'at': '2022-01-05T15:40:57.010950+00:00',
                  'ver': '4',
                  'repliesTo': null,
                  'text': 'forwarded message 2',
                  'editedAt': null,
                  'attachments': []
                },
                'cursor': ''
              }
            },
            'cursor': ''
          }
        }
      ],
      'ver': '5'
    };

    chatEvents.add(QueryResult.internal(
      data: {'chatEvents': event},
      parserFn: (_) => null,
      source: null,
    ));

    return Future.value(
        ForwardChatItems$Mutation.fromJson({'forwardChatItems': event})
                .forwardChatItems
            as ForwardChatItems$Mutation$ForwardChatItems$ChatEventsVersioned);
  });

  when(graphQlProvider.forwardChatItems(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    [
      ChatItemQuoteInput(
        id: const ChatItemId('2fa522d4-47b7-49de-ad34-7a932a312d96'),
        attachments: [],
        withText: true,
      ),
    ],
  )).thenAnswer((_) {
    var event = {
      '__typename': 'ChatEventsVersioned',
      'events': [
        {
          '__typename': 'EventChatItemPosted',
          'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
          'item': {
            'node': {
              '__typename': 'ChatForward',
              'id': '2fa522d4-47b7-49de-ad34-7a932a312d97',
              'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
              'authorId': '0d72d245-8425-467a-9ebd-082d4f47850a',
              'at': '2022-04-27T16:41:38.461547384+00:00',
              'ver': '6',
              'item': {
                'node': {
                  '__typename': 'ChatMessage',
                  'id': '91e6e597-e6ca-4b1f-ad70-83dd621e4cb4',
                  'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                  'authorId': '0d72d245-8425-467a-9ebd-082d4f47850a',
                  'at': '2022-01-05T15:40:57.010950+00:00',
                  'ver': '7',
                  'repliesTo': null,
                  'text': 'forwarded message 3',
                  'editedAt': null,
                  'attachments': []
                },
                'cursor': ''
              }
            },
            'cursor': ''
          }
        }
      ],
      'ver': '8'
    };

    chatEvents.add(QueryResult.internal(
      data: {'chatEvents': event},
      parserFn: (_) => null,
      source: null,
    ));

    return Future.value(
        ForwardChatItems$Mutation.fromJson({'forwardChatItems': event})
                .forwardChatItems
            as ForwardChatItems$Mutation$ForwardChatItems$ChatEventsVersioned);
  });

  when(graphQlProvider.forwardChatItems(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850c'),
    [
      ChatItemQuoteInput(
        id: const ChatItemId('91e6e597-e6ca-4b1f-ad70-83dd621e4cb4'),
        attachments: [],
        withText: true,
      ),
    ],
  )).thenAnswer((_) => Future.value());

  when(graphQlProvider.incomingCalls()).thenAnswer((_) => Future.value(
      IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []})));
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));
  when(graphQlProvider.keepOnline())
      .thenAnswer((_) => Future.value(const Stream.empty()));

  var sessionProvider = Get.put(SessionDataHiveProvider());
  AuthService authService =
      AuthService(AuthRepository(graphQlProvider), SessionDataHiveProvider());
  await authService.init();

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

  var myUserProvider = Get.put(MyUserHiveProvider());
  await myUserProvider.init();
  await myUserProvider.clear();
  var galleryItemProvider = Get.put(GalleryItemHiveProvider());
  await galleryItemProvider.init();
  await galleryItemProvider.clear();
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
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  await applicationSettingsProvider.clear();

  var messagesProvider = Get.put(ChatItemHiveProvider(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
  ));
  await messagesProvider.init();

  Widget createWidgetForTesting({required Widget child}) {
    FlutterError.onError = ignoreOverflowErrors;
    return MaterialApp(
        theme: Themes.light(),
        home: Builder(
          builder: (BuildContext context) {
            router.context = context;
            return Scaffold(body: ContextMenuOverlay(child: child));
          },
        ));
  }

  testWidgets('ChatView successfully forward a message',
      (WidgetTester tester) async {
    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    await authService.init();

    AbstractMyUserRepository myUserRepository =
        MyUserRepository(graphQlProvider, myUserProvider, galleryItemProvider);
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractSettingsRepository settingsRepository = Get.put(
        SettingsRepository(settingsProvider, applicationSettingsProvider));
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
        ChatRepository(graphQlProvider, chatProvider, userRepository));
    AbstractCallRepository callRepository =
        CallRepository(graphQlProvider, userRepository);

    MyUserService myUserService =
        Get.put(MyUserService(authService, myUserRepository));
    Get.put(CallService(authService, settingsRepository, callRepository));
    Get.put(ChatService(chatRepository, myUserService));
    Get.put(UserService(userRepository));

    await tester.pumpWidget(createWidgetForTesting(
      child: const ChatView(ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    var message = find.text('text message', skipOffstage: false);
    expect(message, findsOneWidget);

    await tester.longPress(message);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('SelectMessages')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('CancelForward')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.longPress(message);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('SelectMessages')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('SendForward')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find
        .byKey(const Key('ForwardChat_0d72d245-8425-467a-9ebd-082d4f47850b')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find
        .byKey(const Key('ForwardChat_0d72d245-8425-467a-9ebd-082d4f47850c')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('SendForwardInModal')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    var message1 = find.text('forwarded message', skipOffstage: false);
    expect(message1, findsOneWidget);

    await tester.longPress(message1);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('SelectMessages')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('SendForward')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find
        .byKey(const Key('ForwardChat_0d72d245-8425-467a-9ebd-082d4f47850b')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('SendForwardInModal')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('Send')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    var message2 = find.text('forwarded message 2', skipOffstage: false);
    expect(message2, findsOneWidget);

    await tester.longPress(message2);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('ForwardMessage')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find
        .byKey(const Key('ForwardChat_0d72d245-8425-467a-9ebd-082d4f47850b')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('SendForwardInModal')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('Send')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    var message3 = find.text('forwarded message 3', skipOffstage: false);
    expect(message3, findsOneWidget);

    await Get.deleteAll(force: true);
  });
}

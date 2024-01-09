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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/call.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/call_rect.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_call_credentials.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/favorite_chat.dart';
import 'package:messenger/provider/hive/session_data.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/monolog.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/recent_chat.dart';
import 'package:messenger/provider/hive/credentials.dart';
import 'package:messenger/provider/hive/temp_chat_call_credentials.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/info/controller.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/overflow_error.dart';
import '../mock/platform_utils.dart';
import 'chat_rename_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  PlatformUtils = PlatformUtilsMock();
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/chat_rename_widget');

  const chatData = {
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
    'lastReads': [],
    'lastDelivery': '1970-01-01T00:00:00+00:00',
    'lastItem': null,
    'lastReadItem': null,
    'unreadCount': 0,
    'totalCount': 0,
    'ongoingCall': null,
    'ver': '0'
  };

  const recentChats = {
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

  const favoriteChats = {
    'favoriteChats': {
      'edges': [],
      'pageInfo': {
        'endCursor': 'endCursor',
        'hasNextPage': false,
        'startCursor': 'startCursor',
        'hasPreviousPage': false,
      }
    }
  };

  final credentialsProvider = Get.put(CredentialsHiveProvider());
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

  final graphQlProvider = MockGraphQlProvider();
  Get.put<GraphQlProvider>(graphQlProvider);
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.favoriteChatsEvents(any))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.getUser(any))
      .thenAnswer((_) => Future.value(GetUser$Query.fromJson({'user': null})));
  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  final AuthService authService =
      AuthService(AuthRepository(graphQlProvider), CredentialsHiveProvider());
  await authService.init();

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

  final myUserProvider = Get.put(MyUserHiveProvider());
  await myUserProvider.init();
  await myUserProvider.clear();
  final contactProvider = Get.put(ContactHiveProvider());
  await contactProvider.init();
  await contactProvider.clear();
  final userProvider = Get.put(UserHiveProvider());
  await userProvider.init();
  await userProvider.clear();
  final chatProvider = Get.put(ChatHiveProvider());
  await chatProvider.init();
  await chatProvider.clear();
  final settingsProvider = MediaSettingsHiveProvider();
  await settingsProvider.init();
  await settingsProvider.clear();
  final draftProvider = Get.put(DraftHiveProvider());
  await draftProvider.init();
  await draftProvider.clear();
  final applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  final backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  final callCredentialsProvider = ChatCallCredentialsHiveProvider();
  await callCredentialsProvider.init();
  final tempCallCredentialsProvider = PendingChatCallCredentialsHiveProvider();
  await tempCallCredentialsProvider.init();
  final callRectProvider = CallRectHiveProvider();
  await callRectProvider.init();
  final monologProvider = MonologHiveProvider();
  await monologProvider.init();
  final recentChatProvider = RecentChatHiveProvider();
  await recentChatProvider.init();
  final favoriteChatProvider = FavoriteChatHiveProvider();
  await favoriteChatProvider.init();
  final sessionProvider = SessionDataHiveProvider();
  await sessionProvider.init();

  final messagesProvider = Get.put(ChatItemHiveProvider(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
  ));
  await messagesProvider.init();

  Widget createWidgetForTesting({required Widget child}) {
    FlutterError.onError = ignoreOverflowErrors;
    return MaterialApp(
      theme: Themes.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('ChatView successfully changes chat name',
      (WidgetTester tester) async {
    when(graphQlProvider.recentChatsTopEvents(3))
        .thenAnswer((_) => const Stream.empty());

    final StreamController<QueryResult> chatEvents = StreamController();
    when(graphQlProvider.chatEvents(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      any,
      any,
    )).thenAnswer((_) => const Stream.empty());

    when(graphQlProvider
            .getChat(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer(
            (_) => Future.value(GetChat$Query.fromJson({'chat': chatData})));

    when(graphQlProvider.chatItems(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      last: 50,
    )).thenAnswer((_) => Future.value(GetMessages$Query.fromJson({
          'chat': {
            'items': {'edges': []}
          }
        })));

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

    when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

    when(graphQlProvider.incomingCalls()).thenAnswer((_) => Future.value(
        IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []})));
    when(graphQlProvider.incomingCallsTopEvents(3))
        .thenAnswer((_) => const Stream.empty());

    when(graphQlProvider.renameChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ChatName('newname'),
    )).thenAnswer((_) {
      final event = {
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
              'emails': {'confirmed': []},
              'phones': {'confirmed': []},
              'chatDirectLink': null,
              'hasPassword': false,
              'unreadChatsCount': 0,
              'ver': '0',
              'presence': 'AWAY',
              'online': {'__typename': 'UserOnline'},
              'mutualContactsCount': 0,
              'isDeleted': false,
              'isBlocked': {'ver': '0'},
            },
            'at': DateTime.now().toString(),
          }
        ],
        'ver': '1'
      };

      chatEvents.add(QueryResult.internal(
        data: {'chatEvents': event},
        parserFn: (_) => null,
        source: null,
      ));

      return Future.value(RenameChat$Mutation.fromJson({'renameChat': event})
          .renameChat as RenameChat$Mutation$RenameChat$ChatEventsVersioned);
    });

    final AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        credentialsProvider,
      ),
    );
    await authService.init();

    final UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));
    final AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );
    final AbstractCallRepository callRepository = CallRepository(
      graphQlProvider,
      userRepository,
      callCredentialsProvider,
      tempCallCredentialsProvider,
      settingsRepository,
      me: const UserId('me'),
    );
    final AbstractChatRepository chatRepository =
        Get.put<AbstractChatRepository>(
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

    Get.put(UserService(userRepository));
    final ChatService chatService =
        Get.put(ChatService(chatRepository, authService));
    Get.put(CallService(authService, chatService, callRepository));

    await tester.pumpWidget(createWidgetForTesting(
      child: const ChatInfoView(ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')),
    ));

    // TODO: This waits for lazy [Hive] boxes to finish receiving events, which
    //       should be done in a more strict way.
    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() => Future.delayed(1.milliseconds));
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('MoreButton'), skipOffstage: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('EditButton'), skipOffstage: false));
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('RenameChatField'));
    expect(field, findsOneWidget);

    await tester.tap(field);
    await tester.pumpAndSettle();

    await tester.enterText(field, 'newname');
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byIcon(Icons.check), findsNothing);

    verify(graphQlProvider.renameChat(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
      ChatName('newname'),
    ));

    expect(find.text('newname'), findsNWidgets(2));

    await Get.deleteAll(force: true);
  });

  await myUserProvider.clear();
  await contactProvider.clear();
  await userProvider.clear();
  await chatProvider.clear();
}

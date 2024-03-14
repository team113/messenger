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

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/contact.dart';
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
import 'package:messenger/provider/hive/chat_credentials.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/contact_sorting.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/favorite_chat.dart';
import 'package:messenger/provider/hive/favorite_contact.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session_data.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/monolog.dart';
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
import 'package:messenger/ui/page/home/page/chat/info/view.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/platform_utils.dart';
import 'chat_direct_link_chat_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  PlatformUtils = PlatformUtilsMock();
  TestWidgetsFlutterBinding.ensureInitialized();
  Config.disableInfiniteAnimations = true;
  Hive.init('./test/.temp_hive/chat_direct_link_widget');

  var chatData = {
    '__typename': 'Chat',
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
    'avatar': null,
    'name': 'null',
    'members': {'nodes': [], 'totalCount': 0},
    'kind': 'GROUP',
    'isHidden': false,
    'muted': null,
    'directLink': null,
    'createdAt': '2021-12-27T14:19:14.828+00:00',
    'updatedAt': '2021-12-27T14:19:14.828+00:00',
    'lastReads': [],
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

  var graphQlProvider = Get.put(MockGraphQlProvider());
  when(graphQlProvider.disconnect()).thenAnswer((_) => Future.value);

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

  AuthService authService = Get.put(
    AuthService(AuthRepository(graphQlProvider), credentialsProvider),
  );
  authService.init();

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
  var draftProvider = Get.put(DraftHiveProvider());
  await draftProvider.init();
  await draftProvider.clear();
  var mediaSettingsProvider = MediaSettingsHiveProvider();
  await mediaSettingsProvider.init();
  await mediaSettingsProvider.clear();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  var chatItemHiveProvider = ChatItemHiveProvider(
      const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'));
  await chatItemHiveProvider.init();
  await chatItemHiveProvider.clear();
  final callCredentialsProvider = CallCredentialsHiveProvider();
  await callCredentialsProvider.init();
  final chatCredentialsProvider = ChatCredentialsHiveProvider();
  await chatCredentialsProvider.init();
  final callRectProvider = CallRectHiveProvider();
  await callRectProvider.init();
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
  var blocklistProvider = BlocklistHiveProvider();
  await blocklistProvider.init();
  var blocklistSortingProvider = BlocklistSortingHiveProvider();
  await blocklistSortingProvider.init();
  var myUserProvider = Get.put(MyUserHiveProvider());
  await myUserProvider.init();
  await myUserProvider.clear();

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      theme: Themes.light(),
      home: Builder(
        builder: (context) {
          router.context = context;
          return Scaffold(body: child);
        },
      ),
    );
  }

  testWidgets('ChatInfoView successfully updates ChatDirectLink',
      (WidgetTester tester) async {
    BigInt ver = BigInt.one;
    when(graphQlProvider.disconnect()).thenAnswer((_) => Future.value);
    when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

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

    when(graphQlProvider.incomingCalls()).thenAnswer((_) => Future.value(
        IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []})));

    when(graphQlProvider.incomingCallsTopEvents(3))
        .thenAnswer((_) => const Stream.empty());

    when(graphQlProvider.createChatDirectLink(any,
            groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer((_) {
      ver = ver + BigInt.one;
      var event = {
        '__typename': 'ChatEventsVersioned',
        'events': [
          {
            '__typename': 'EventChatDirectLinkUpdated',
            'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
            'directLink': {'slug': 'link', 'usageCount': 0}
          }
        ],
        'ver': '$ver'
      };

      chatEvents.add(QueryResult.internal(
        data: {'chatEvents': event},
        parserFn: (_) => null,
        source: null,
      ));

      return Future.value(CreateChatDirectLink$Mutation.fromJson({
        'createChatDirectLink': event,
      }).createChatDirectLink as ChatEventsVersionedMixin?);
    });

    when(graphQlProvider.deleteChatDirectLink(
      groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    )).thenAnswer(
      (_) {
        ver = ver + BigInt.one;
        var event = {
          '__typename': 'ChatEventsVersioned',
          'events': [
            {
              '__typename': 'EventChatDirectLinkDeleted',
              'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
            }
          ],
          'ver': '$ver'
        };
        chatEvents.add(QueryResult.internal(
          data: {'chatEvents': event},
          parserFn: (_) => null,
          source: null,
        ));

        return Future.value();
      },
    );

    when(graphQlProvider.contactsEvents(any)).thenAnswer(
      (_) => Stream.fromIterable([
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'chatContactsEvents': {
              '__typename': 'ChatContactsList',
              'chatContacts': {'nodes': [], 'ver': '0'},
              'favoriteChatContacts': {'nodes': []},
            }
          },
        )
      ]),
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

    when(graphQlProvider.myUserEvents(any))
        .thenAnswer((_) => const Stream.empty());

    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));
    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        mediaSettingsProvider,
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
    AbstractContactRepository contactRepository = ContactRepository(
      graphQlProvider,
      contactProvider,
      favoriteContactHiveProvider,
      contactSortingHiveProvider,
      UserRepository(graphQlProvider, userProvider),
      sessionProvider,
    );

    Get.put(ContactService(contactRepository));
    Get.put(UserService(userRepository));
    ChatService chatService = Get.put(ChatService(chatRepository, authService));
    Get.put(CallService(authService, chatService, callRepository));

    BlocklistRepository blocklistRepository = BlocklistRepository(
      graphQlProvider,
      blocklistProvider,
      blocklistSortingProvider,
      userRepository,
      sessionProvider,
    );

    MyUserRepository myUserRepository = Get.put(
      MyUserRepository(
        graphQlProvider,
        myUserProvider,
        blocklistRepository,
        userRepository,
      ),
    );
    Get.put(MyUserService(authService, myUserRepository));

    await tester.pumpWidget(createWidgetForTesting(
      child: const ChatInfoView(ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')),
    ));

    // TODO: This waits for lazy [Hive] boxes to finish receiving events, which
    //       should be done in a more strict way.
    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() => Future.delayed(1.milliseconds));
    }
    await tester.pumpAndSettle(const Duration(seconds: 20));

    final editLink = find.byKey(const Key('EditLinkButton'));
    await tester.dragUntilVisible(
      editLink,
      find.byKey(const Key('ChatInfoScrollable')),
      const Offset(0, 100),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('EditLinkButton')));
    await tester.pumpAndSettle();

    final link = find.byKey(const Key('LinkField'), skipOffstage: false);
    await tester.dragUntilVisible(
      link,
      find.byKey(const Key('ChatInfoScrollable')),
      const Offset(1, 0),
    );

    await tester.pumpAndSettle();

    await tester.tap(link);
    await tester.pumpAndSettle();

    await tester.enterText(link, 'newlink');
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byIcon(Icons.check), findsNothing);

    verify(graphQlProvider.createChatDirectLink(
      any,
      groupId: const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    ));

    await Get.deleteAll(force: true);
  });

  await contactProvider.clear();
  await userProvider.clear();
  await chatProvider.clear();
}

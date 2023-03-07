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

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/precise_date_time/src/non_web.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/call.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/chat_call_credentials.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/contact.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/info/view.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/overflow_error.dart';
import 'chat_direct_link_chat_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/chat_direct_link_widget');

  var chatData = {
    '__typename': 'Chat',
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
    'avatar': null,
    'name': 'null',
    'members': {'nodes': []},
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

  var graphQlProvider = Get.put(MockGraphQlProvider());
  when(graphQlProvider.disconnect()).thenAnswer((_) => Future.value);

  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  await sessionProvider.clear();
  sessionProvider.setCredentials(
    Credentials(
      Session(
        const AccessToken('token'),
        PreciseDateTime.now().add(const Duration(days: 1)),
      ),
      RememberedSession(
        const RememberToken('token'),
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

  AuthService authService =
      Get.put(AuthService(AuthRepository(graphQlProvider), sessionProvider));
  await authService.init();

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

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
  var credentialsProvider = ChatCallCredentialsHiveProvider();
  await credentialsProvider.init();

  Widget createWidgetForTesting({required Widget child}) {
    FlutterError.onError = ignoreOverflowErrors;
    return MaterialApp(
      theme: Themes.light(),
      home: Scaffold(body: child),
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
    )).thenAnswer((_) => const Stream.empty());

    when(graphQlProvider
            .getChat(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')))
        .thenAnswer(
            (_) => Future.value(GetChat$Query.fromJson({'chat': chatData})));

    when(graphQlProvider.recentChats(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

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

    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        mediaSettingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
      ),
    );
    AbstractCallRepository callRepository = CallRepository(
      graphQlProvider,
      userRepository,
      credentialsProvider,
      settingsRepository,
      me: const UserId('me'),
    );
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        chatProvider,
        callRepository,
        draftProvider,
        userRepository,
        sessionProvider,
      ),
    );
    AbstractContactRepository contactRepository = ContactRepository(
      graphQlProvider,
      contactProvider,
      UserRepository(graphQlProvider, userProvider, galleryItemProvider),
      sessionProvider,
    );

    Get.put(ContactService(contactRepository));
    Get.put(UserService(userRepository));
    ChatService chatService = Get.put(ChatService(chatRepository, authService));
    Get.put(CallService(authService, chatService, callRepository));

    await tester.pumpWidget(createWidgetForTesting(
      child: const ChatInfoView(ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 20));

    final link = find.byKey(const Key('LinkField'), skipOffstage: false);
    await tester.dragUntilVisible(
      link,
      find.byKey(const Key('ChatInfoListView')),
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

  await galleryItemProvider.clear();
  await contactProvider.clear();
  await userProvider.clear();
  await chatProvider.clear();
}

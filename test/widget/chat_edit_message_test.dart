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
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/model/chat.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/view.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/overflow_error.dart';
import 'chat_edit_message_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/chat_edit_message_text_widget');

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
      {'memberId': 'me', 'at': '2022-01-01T07:27:30.151628+00:00'},
    ],
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

  var graphQlProvider = Get.put<GraphQlProvider>(MockGraphQlProvider());
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(graphQlProvider.keepOnline())
      .thenAnswer((_) => Future.value(const Stream.empty()));

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  final StreamController<QueryResult> chatEvents = StreamController();
  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    ChatVersion('0'),
  )).thenAnswer((_) => Future.value(chatEvents.stream));

  when(graphQlProvider
          .keepTyping(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  when(graphQlProvider
          .getChat(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')))
      .thenAnswer((_) => Future.value(GetChat$Query.fromJson(chatData)));

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
                  'id': '91e6e597-e6ca-4b1f-ad70-83dd621e4cb2',
                  'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                  'authorId': 'me',
                  'at': DateTime.now().toIso8601String(),
                  'ver': '0',
                  'repliesTo': [],
                  'text': 'edit message',
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

  when(graphQlProvider.incomingCalls()).thenAnswer((_) => Future.value(
      IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []})));
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  when(graphQlProvider.editChatMessageText(
    const ChatItemId('91e6e597-e6ca-4b1f-ad70-83dd621e4cb2'),
    const ChatMessageText('new text'),
  )).thenAnswer((_) {
    var event = {
      '__typename': 'ChatEventsVersioned',
      'events': [
        {
          '__typename': 'EventChatItemTextEdited',
          'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
          'itemId': '91e6e597-e6ca-4b1f-ad70-83dd621e4cb2',
          'text': 'new text',
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
        EditChatMessageText$Mutation.fromJson({'editChatMessageText': event})
            .editChatMessageText as ChatEventsVersionedMixin?);
  });

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
  var settingsProvider = Get.put(MediaSettingsHiveProvider());
  await settingsProvider.init();
  await settingsProvider.clear();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();

  var messagesProvider = Get.put(ChatItemHiveProvider(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
  ));
  await messagesProvider.init();
  await messagesProvider.clear();

  Widget createWidgetForTesting({required Widget child}) {
    FlutterError.onError = ignoreOverflowErrors;
    return MaterialApp(
        theme: Themes.light(),
        home: Builder(
          builder: (BuildContext context) {
            router.context = context;
            return Scaffold(body: child);
          },
        ));
  }

  testWidgets('ChatView successfully edits a ChatMessage',
      (WidgetTester tester) async {
    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    await authService.init();

    router = RouterState(authService);
    router.provider = MockPlatformRouteInformationProvider();

    UserRepository userRepository =
        UserRepository(graphQlProvider, userProvider, galleryItemProvider);
    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
        ChatRepository(graphQlProvider, chatProvider, userRepository));
    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
      ),
    );
    AbstractCallRepository callRepository =
        CallRepository(graphQlProvider, userRepository);

    Get.put(UserService(userRepository));
    Get.put(CallService(authService, settingsRepository, callRepository));
    Get.put(ChatService(chatRepository, authService));

    await tester.pumpWidget(createWidgetForTesting(
      child: const ChatView(ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    var message = find.text('edit message', skipOffstage: false);
    expect(message, findsOneWidget);
    await tester.longPress(message);
    await tester.pumpAndSettle(const Duration(seconds: 10));

    await tester.tap(find.byKey(const Key('EditButton')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.enterText(
      find.byKey(const Key('MessageEditField')),
      'new text',
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      find.text('edit message', skipOffstage: false),
      findsNothing,
    );
    expect(find.text('new text', skipOffstage: false), findsOneWidget);

    await Get.deleteAll(force: true);
  });
}

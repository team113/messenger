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
import 'package:flutter_list_view/flutter_list_view.dart';
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
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/widget/context_menu/overlay.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_reply_message_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  const String chatId = '0d72d245-8425-467a-9ebd-082d4f47850b';
  const int maxText = ChatMessageText.maxLength;
  final String expectMaxText1 = 'A' * maxText;
  final String expectMaxText2 = 'B' * maxText;
  const String expectText3 = 'A';

  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/chat_reply_message_widget');

  final Map<String, Object?> chatData = {
    'id': chatId,
    'name': null,
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
    'gallery': {'nodes': []},
    'unreadCount': 0,
    'totalCount': 0,
    'ongoingCall': null,
    'ver': '0'
  };
  final Map<String, Map<String, List<Map<String, Object?>>>> recentChats = {
    'recentChats': {
      'nodes': [chatData]
    }
  };
  final GraphQlProvider graphQlProvider =
      Get.put<GraphQlProvider>(MockGraphQlProvider());

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  final StreamController<QueryResult> chatEvents = StreamController();
  when(graphQlProvider.chatEvents(
    const ChatId(chatId),
    ChatVersion('0'),
  )).thenAnswer((_) => Future.value(chatEvents.stream));

  when(graphQlProvider.keepTyping(const ChatId(chatId)))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  when(graphQlProvider.chatItems(
    const ChatId(chatId),
    first: 120,
  )).thenAnswer(
    (_) => Future.value(
      GetMessages$Query.fromJson(
        {
          'chat': {
            'items': {'edges': []}
          }
        },
      ),
    ),
  );

  when(graphQlProvider.recentChats(
    first: 120,
    after: null,
    last: null,
    before: null,
  )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

  when(graphQlProvider.postChatMessage(
    const ChatId(chatId),
    text: ChatMessageText(expectMaxText1),
    attachments: anyNamed('attachments'),
    repliesTo: [],
  )).thenAnswer((_) => Future.value());

  when(graphQlProvider.postChatMessage(
    const ChatId(chatId),
    text: ChatMessageText(expectMaxText2),
    attachments: anyNamed('attachments'),
    repliesTo: [],
  )).thenAnswer((_) => Future.value());

  when(graphQlProvider.postChatMessage(
    const ChatId(chatId),
    text: const ChatMessageText(expectText3),
    attachments: anyNamed('attachments'),
    repliesTo: [],
  )).thenAnswer((_) => Future.value());

  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => Future.value(const Stream.empty()));

  final SessionDataHiveProvider sessionProvider =
      Get.put(SessionDataHiveProvider());
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

  final AuthService authService =
      AuthService(AuthRepository(graphQlProvider), SessionDataHiveProvider());
  await authService.init();

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

  final GalleryItemHiveProvider galleryItemProvider =
      Get.put(GalleryItemHiveProvider());
  await galleryItemProvider.init();
  await galleryItemProvider.clear();
  final ContactHiveProvider contactProvider = Get.put(ContactHiveProvider());
  await contactProvider.init();
  await contactProvider.clear();
  final UserHiveProvider userProvider = Get.put(UserHiveProvider());
  await userProvider.init();
  await userProvider.clear();
  final ChatHiveProvider chatProvider = Get.put(ChatHiveProvider());
  await chatProvider.init();
  await chatProvider.clear();
  final MediaSettingsHiveProvider settingsProvider =
      MediaSettingsHiveProvider();
  await settingsProvider.init();
  await settingsProvider.clear();
  final ApplicationSettingsHiveProvider applicationSettingsProvider =
      ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  final BackgroundHiveProvider backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();

  final ChatItemHiveProvider messagesProvider =
      Get.put(ChatItemHiveProvider(const ChatId(chatId)));
  await messagesProvider.init(userId: const UserId('me'));
  await messagesProvider.clear();

  Future<Widget> createWidgetForTesting({required Widget child}) async {
    final AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    await authService.init();

    final UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    final AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
      ),
    );
    final AbstractChatRepository chatRepository =
        Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        chatProvider,
        userRepository,
        me: const UserId('me'),
      ),
    );
    final AbstractCallRepository callRepository =
        CallRepository(graphQlProvider, userRepository);

    Get.put(UserService(userRepository));
    Get.put(CallService(authService, settingsRepository, callRepository));
    Get.put(ChatService(chatRepository, authService));

    return MaterialApp(
      theme: Themes.light(),
      home: Builder(
        builder: (BuildContext context) {
          router.context = context;
          return Scaffold(body: ContextMenuOverlay(child: child));
        },
      ),
    );
  }

  testWidgets(
    'ChatService splits (${maxText * 2} + 1) symbols into 3 messages',
    (WidgetTester tester) async {
      const Duration duration = Duration(seconds: 2);
      const double delta = 100;
      final List<String> expectMessages = [
        expectMaxText1,
        expectMaxText1,
        expectText3,
      ];
      final int maxScrolls = expectMessages.length * 50;
      final String inputText = expectMessages.join();
      await tester.pumpWidget(
        await createWidgetForTesting(
          child: const ChatView(ChatId(chatId)),
        ),
      );
      await tester.pumpAndSettle(duration);
      await _input(tester, inputText, duration);

      final Set<String> quantityMessages = {};
      try {
        await tester.scrollUntilVisible(
          find.byWidgetPredicate(
            (Widget widget) {
              if (widget is ChatItemWidget) {
                final ChatItem chatItem = widget.item.value;
                if (chatItem is ChatMessage) {
                  quantityMessages.add(chatItem.id.val);
                  // if (chatItem.text?.val.length != maxText) {
                  //   return true;
                  // } 
                }
              }
              return false;
            },
            skipOffstage: false,
          ),
          scrollable: find.descendant(
            of: find.byType(FlutterListView),
            matching: find.byType(Scrollable),
          ),
          maxScrolls: maxScrolls,
          delta,
        );
      } catch (_) {
        // No-op.
      }
      await tester.pumpAndSettle(duration);
      expect(quantityMessages.length, expectMessages.length);

      await Get.deleteAll(force: true);
    },
  );
}

Future<void> _input(
  WidgetTester tester,
  String inputText,
  Duration duration,
) async {
  final Finder messageField = find.byKey(const Key('MessageField'));
  await tester.enterText(messageField, inputText);
  await tester.pumpAndSettle(duration);

  final Finder buttonSend = find.byKey(const Key('Send'));
  await tester.tap(buttonSend);
  await tester.pumpAndSettle(duration);
}




//       FlutterListView listView = find.byType(FlutterListView).evaluate().single.widget
//           as FlutterListView;
// listView.
//       expect(listView.delegate.estimatedChildCount, 2);




      // final Finder finderMessages = find.byWidgetPredicate(
      //   (Widget widget) =>
      //       widget is ChatItemWidget && widget.item.value is ChatMessage,
      //   skipOffstage: false,
      // );
      // final Iterable<Element> listsMessages = finderMessages.evaluate();
      // expect(listsMessages.length, expectMessages.length);
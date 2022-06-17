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
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/my_profile/controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_direct_link_user_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/chat_direct_link_user_widget');
  var userData = {
    'id': '12345',
    'num': '1234567890123456',
    'login': 'login',
    'name': 'name',
    'bio': 'bio',
    'emails': {'confirmed': [], 'unconfirmed': null},
    'phones': {'confirmed': [], 'unconfirmed': null},
    'gallery': {'nodes': []},
    'hasPassword': true,
    'unreadChatsCount': 0,
    'ver': '0',
    'online': {'__typename': 'UserOnline'},
    'presence': 'AWAY',
  };

  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => Future.value);
  var sessionProvider = SessionDataHiveProvider();
  AuthService authService =
      AuthService(AuthRepository(graphQlProvider), sessionProvider);
  await authService.init();
  await sessionProvider.init();

  router = RouterState(authService);
  router.provider = MockPlatformRouteInformationProvider();

  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  await myUserProvider.clear();
  var galleryItemProvider = GalleryItemHiveProvider();
  await galleryItemProvider.init();
  var contactProvider = ContactHiveProvider();
  await contactProvider.init();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  var chatProvider = ChatHiveProvider();
  await chatProvider.init();

  Get.put(myUserProvider);
  Get.put(galleryItemProvider);
  Get.put(contactProvider);
  Get.put(userProvider);
  Get.put<GraphQlProvider>(graphQlProvider);
  Get.put(sessionProvider);
  Get.put(chatProvider);

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      theme: Themes.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('MyProfileView successfully updates and deletes ChatDirectLink',
      (WidgetTester tester) async {
    final StreamController<QueryResult> myUserEvents = StreamController();
    when(graphQlProvider.myUserEvents(null)).thenAnswer((_) {
      myUserEvents.add(
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'myUserEvents': {'__typename': 'MyUser', ...userData},
          },
        ),
      );

      return Future.value(myUserEvents.stream);
    });
    when(graphQlProvider.keepOnline())
        .thenAnswer((_) => Future.value(const Stream.empty()));

    when(graphQlProvider.createUserDirectLink(any)).thenAnswer((_) {
      var event = {
        '__typename': 'MyUserEventsVersioned',
        'events': [
          {
            '__typename': 'EventUserDirectLinkUpdated',
            'userId': 'id',
            'directLink': {'slug': 'link', 'usageCount': 0},
          }
        ],
        'myUser': userData,
        'ver': '${(myUserProvider.myUser!.ver.internal + BigInt.one)}',
      };

      myUserEvents.add(QueryResult.internal(
        data: {'myUserEvents': event},
        parserFn: (_) => null,
        source: null,
      ));

      return Future.value(CreateUserDirectLink$Mutation.fromJson({
        'createChatDirectLink': event,
      }).createChatDirectLink as MyUserEventsVersionedMixin?);
    });

    when(graphQlProvider.deleteUserDirectLink()).thenAnswer((_) {
      var event = {
        '__typename': 'MyUserEventsVersioned',
        'events': [
          {
            '__typename': 'EventUserDirectLinkDeleted',
            'userId': 'id',
          }
        ],
        'myUser': userData,
        'ver': '${(myUserProvider.myUser!.ver.internal + BigInt.one)}',
      };

      myUserEvents.add(QueryResult.internal(
        data: {'myUserEvents': event},
        parserFn: (_) => null,
        source: null,
      ));

      return Future.value(DeleteUserDirectLink$Mutation.fromJson({
        'deleteChatDirectLink': event,
      }).deleteChatDirectLink as MyUserEventsVersionedMixin?);
    });

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );

    AbstractMyUserRepository myUserRepository =
        MyUserRepository(graphQlProvider, myUserProvider, galleryItemProvider);
    await authService.init();
    Get.put(MyUserService(authService, myUserRepository));

    await tester
        .pumpWidget(createWidgetForTesting(child: const MyProfileView()));
    await tester.pumpAndSettle();

    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.dragUntilVisible(
        find.byKey(const Key('ChatDirectLinkExpandable')),
        find.byKey(const Key('MyProfileColumn')),
        const Offset(1, 0));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('ChatDirectLinkExpandable')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('GenerateChatDirectLink')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byKey(const Key('RemoveChatDirectLink')), findsOneWidget);

    await tester.tap(find.byKey(const Key('RemoveChatDirectLink')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byKey(const Key('RemoveChatDirectLink')), findsNothing);

    var field = find.byKey(const Key('DirectChatLinkTextField'));
    expect(field, findsOneWidget);

    await tester.tap(field);
    await tester.pumpAndSettle();

    await tester.enterText(field, 'newlink');
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('RemoveChatDirectLink')), findsOneWidget);

    await tester.tap(find.byKey(const Key('RemoveChatDirectLink')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byKey(const Key('RemoveChatDirectLink')), findsNothing);

    verifyInOrder([
      graphQlProvider.myUserEvents(null),
      graphQlProvider.createUserDirectLink(any),
      graphQlProvider.deleteUserDirectLink(),
      graphQlProvider.createUserDirectLink(ChatDirectLinkSlug('newlink')),
      graphQlProvider.deleteUserDirectLink(),
    ]);

    await Get.deleteAll(force: true);
  });
}

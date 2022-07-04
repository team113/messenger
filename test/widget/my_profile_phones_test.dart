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

// ignore_for_file: null_argument_to_non_null_type

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/fluent/extension.dart';
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
import 'package:messenger/ui/page/home/page/my_profile/controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'my_profile_phones_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/my_profile_phones_widget');

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

  var sessionProvider = SessionDataHiveProvider();
  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
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
    return MaterialApp(home: Builder(
      builder: (BuildContext context) {
        router.context = context;
        return Scaffold(body: ScaffoldMessenger(child: child));
      },
    ));
  }

  testWidgets('MyProfileView successfully adds and confirms phone',
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

    when(graphQlProvider.addUserPhone(UserPhone('+380999999999'))).thenAnswer(
      (_) {
        var event = {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserPhoneAdded',
              'userId': 'id',
              'phone': '+380999999999',
              'at': DateTime.now().toString(),
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

        return Future.value(
            AddUserPhone$Mutation.fromJson({'addUserPhone': event}).addUserPhone
                as AddUserPhone$Mutation$AddUserPhone$MyUserEventsVersioned);
      },
    );

    when(graphQlProvider.resendPhone()).thenAnswer((_) => Future.value());

    when(graphQlProvider.confirmPhoneCode(ConfirmationCode('1234'))).thenAnswer(
      (_) {
        var event = {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserPhoneConfirmed',
              'userId': 'id',
              'phone': '+380999999999',
              'at': DateTime.now().toString(),
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

        return Future.value(ConfirmUserPhone$Mutation.fromJson(
                {'confirmUserPhone': event}).confirmUserPhone
            as ConfirmUserPhone$Mutation$ConfirmUserPhone$MyUserEventsVersioned);
      },
    );

    when(graphQlProvider.deleteUserPhone(UserPhone('+380999999999')))
        .thenAnswer(
      (_) {
        var event = {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserPhoneDeleted',
              'userId': 'id',
              'phone': '+380999999999',
              'at': DateTime.now().toString(),
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

        return Future.value(
            DeleteUserPhone$Mutation.fromJson({'deleteUserPhone': event})
                .deleteUserPhone);
      },
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );

    AbstractMyUserRepository myUserRepository =
        MyUserRepository(graphQlProvider, myUserProvider, galleryItemProvider);
    await authService.init();
    MyUserService myUserService =
        Get.put(MyUserService(authService, myUserRepository));

    await tester
        .pumpWidget(createWidgetForTesting(child: const MyProfileView()));

    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.dragUntilVisible(find.byKey(const Key('PhonesExpandable')),
        find.byKey(const Key('MyProfileScrollable')), const Offset(1, 0));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('PhonesExpandable')));

    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.enterText(
        find.byKey(const Key('PhoneInput')), '+380999999999');
    expect(find.text('label_unconfirmed'.td()), findsNothing);

    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.dragUntilVisible(find.byKey(const Key('AddPhoneButton')),
        find.byKey(const Key('MyProfileScrollable')), const Offset(1, 0));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('AddPhoneButton')), findsOneWidget);
    await tester.tap(find.byKey(const Key('AddPhoneButton')));

    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('label_unconfirmed'.td()), findsOneWidget);
    expect(myUserService.myUser.value?.phones.unconfirmed, isNotNull);

    await tester.pump(const Duration(seconds: 30));

    await tester.dragUntilVisible(find.byKey(const Key('ResendPhoneCode')),
        find.byKey(const Key('MyProfileScrollable')), const Offset(1, 0));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('ResendPhoneCode')));
    await tester.pumpAndSettle(const Duration(seconds: 50));

    await tester.enterText(find.byKey(const Key('PhoneCodeInput')), '1234');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('ConfirmPhoneCodeButton')));

    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('+380999999999'), findsOneWidget);
    expect(find.byKey(const Key('DeleteConfirmedPhone')), findsOneWidget);
    expect(myUserService.myUser.value?.phones.confirmed, isNotEmpty);

    await tester.tap(find.byKey(const Key('DeleteConfirmedPhone')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('AlertYesButton')));

    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(myUserService.myUser.value?.phones.confirmed, isEmpty);

    verifyInOrder([
      graphQlProvider.myUserEvents(null),
      graphQlProvider.addUserPhone(UserPhone('+380999999999')),
      graphQlProvider.resendPhone(),
      graphQlProvider.confirmPhoneCode(ConfirmationCode('1234')),
      graphQlProvider.deleteUserPhone(UserPhone('+380999999999')),
    ]);

    await Get.deleteAll(force: true);
  });
}

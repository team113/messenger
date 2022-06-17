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
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/gallery_item.dart';
import 'package:messenger/domain/model/native_file.dart';
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
import 'package:messenger/ui/page/home/page/my_profile/controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'my_profile_gallery_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/my_profile_gallery_widget');
  Config.url = 'http://testUrl.com';
  Config.port = 0;
  var userData = {
    'id': 'id',
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
  await myUserProvider.clear();
  var contactProvider = ContactHiveProvider();
  await contactProvider.init();
  await contactProvider.clear();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  await userProvider.clear();
  var chatProvider = ChatHiveProvider();
  await chatProvider.init();
  await chatProvider.clear();

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

  testWidgets(
      'MyProfileView successfully adds and deletes gallery items, avatar and call cover',
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

    when(graphQlProvider.uploadUserGalleryItem(
      any,
      onSendProgress: anyNamed('onSendProgress'),
    )).thenAnswer(
      (_) {
        var events = {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserGalleryItemAdded',
              'userId': 'id',
              'galleryItem': {
                '__typename': 'ImageGalleryItem',
                'id': 'testId',
                'square': '/test.jpg',
                'original': '/test.jpg',
                'addedAt': DateTime.now().toString()
              },
              'at': DateTime.now().toString()
            }
          ],
          'myUser': userData,
          'ver': (myUserProvider.myUser?.ver.internal == null
                  ? BigInt.zero + BigInt.one
                  : myUserProvider.myUser!.ver.internal + BigInt.one)
              .toString(),
        };
        myUserEvents.add(QueryResult.internal(
          data: {'myUserEvents': events},
          parserFn: (_) => null,
          source: null,
        ));

        return Future.value(UploadUserGalleryItem$Mutation.fromJson(
                {'uploadUserGalleryItem': events}).uploadUserGalleryItem
            as MyUserEventsVersionedMixin?);
      },
    );

    when(graphQlProvider.deleteUserGalleryItem(const GalleryItemId('testId')))
        .thenAnswer(
      (_) {
        var events = {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserGalleryItemDeleted',
              'userId': 'id',
              'galleryItemId': 'testId',
              'at': DateTime.now().toString()
            }
          ],
          'myUser': userData,
          'ver': (myUserProvider.myUser?.ver.internal == null
                  ? BigInt.zero + BigInt.one
                  : myUserProvider.myUser!.ver.internal + BigInt.one)
              .toString(),
        };
        myUserEvents.add(QueryResult.internal(
          data: {'myUserEvents': events},
          parserFn: (_) => null,
          source: null,
        ));

        return Future.value(DeleteUserGalleryItem$Mutation.fromJson(
            {'deleteUserGalleryItem': events}).deleteUserGalleryItem);
      },
    );

    when(graphQlProvider.updateUserAvatar(const GalleryItemId('testId'), null))
        .thenAnswer(
      (_) {
        var events = {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserAvatarUpdated',
              'userId': 'id',
              'avatar': {
                '__typename': 'UserAvatar',
                'galleryItemId': 'testId',
                'crop': null,
                'original': 'orig.png',
                'full': 'cc.full.jpg',
                'big': 'cc.big.jpg',
                'medium': 'cc.medium.jpg',
                'small': 'cc.small.jpg',
              },
              'at': DateTime.now().toString()
            }
          ],
          'myUser': userData,
          'ver': (myUserProvider.myUser?.ver.internal == null
                  ? BigInt.zero + BigInt.one
                  : myUserProvider.myUser!.ver.internal + BigInt.one)
              .toString(),
        };
        myUserEvents.add(QueryResult.internal(
          data: {'myUserEvents': events},
          parserFn: (_) => null,
          source: null,
        ));
        return Future.value(
            UpdateUserAvatar$Mutation.fromJson({'updateUserAvatar': events})
                .updateUserAvatar as MyUserEventsVersionedMixin?);
      },
    );

    when(graphQlProvider.updateUserCallCover(
            const GalleryItemId('testId'), null))
        .thenAnswer(
      (_) {
        var events = {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserCallCoverUpdated',
              'userId': 'id',
              'callCover': {
                '__typename': 'UserCallCover',
                'galleryItemId': 'testId',
                'crop': null,
                'original': 'orig.png',
                'full': 'cc.full.jpg',
                'vertical': 'cc.vertical.jpg',
                'square': 'cc.square.jpg'
              },
              'at': DateTime.now().toString()
            }
          ],
          'myUser': userData,
          'ver': (myUserProvider.myUser?.ver.internal == null
                  ? BigInt.zero + BigInt.one
                  : myUserProvider.myUser!.ver.internal + BigInt.two)
              .toString()
        };
        myUserEvents.add(QueryResult.internal(
          data: {'myUserEvents': events},
          parserFn: (_) => null,
          source: null,
        ));
        return Future.value(UpdateUserCallCover$Mutation.fromJson(
                {'updateUserCallCover': events}).updateUserCallCover
            as MyUserEventsVersionedMixin?);
      },
    );

    when(graphQlProvider.updateUserAvatar(null, null)).thenAnswer(
      (_) {
        var events = {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserAvatarDeleted',
              'userId': 'id',
              'at': DateTime.now().toString()
            }
          ],
          'myUser': userData,
          'ver': (myUserProvider.myUser?.ver.internal == null
                  ? BigInt.zero + BigInt.one
                  : myUserProvider.myUser!.ver.internal + BigInt.one)
              .toString()
        };
        myUserEvents.add(QueryResult.internal(
          data: {'myUserEvents': events},
          parserFn: (_) => null,
          source: null,
        ));
        return Future.value(
            UpdateUserAvatar$Mutation.fromJson({'updateUserAvatar': events})
                .updateUserAvatar as MyUserEventsVersionedMixin?);
      },
    );

    when(graphQlProvider.updateUserCallCover(null, null)).thenAnswer(
      (_) {
        var events = {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserCallCoverDeleted',
              'userId': 'id',
              'at': DateTime.now().toString()
            }
          ],
          'myUser': userData,
          'ver': (myUserProvider.myUser?.ver.internal == null
                  ? BigInt.zero + BigInt.one
                  : myUserProvider.myUser!.ver.internal + BigInt.two)
              .toString()
        };
        myUserEvents.add(QueryResult.internal(
          data: {'myUserEvents': events},
          parserFn: (_) => null,
          source: null,
        ));
        return Future.value(UpdateUserCallCover$Mutation.fromJson(
                {'updateUserCallCover': events}).updateUserCallCover
            as MyUserEventsVersionedMixin?);
      },
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );

    AbstractMyUserRepository myUserRepository = Get.put(
        MyUserRepository(graphQlProvider, myUserProvider, galleryItemProvider));
    await authService.init();
    MyUserService myUserService =
        Get.put(MyUserService(authService, myUserRepository));

    await tester
        .pumpWidget(createWidgetForTesting(child: const MyProfileView()));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('AddGallery')), findsOneWidget);
    Get.find<MyUserService>().uploadGalleryItem(
      NativeFile(
        name: 'test.jpg',
        size: 2,
        bytes: Uint8List.fromList([1, 1]),
      ),
    );
    await mockNetworkImagesFor(
        () async => await tester.pumpAndSettle(const Duration(seconds: 2)));
    expect(find.byKey(const Key('DeleteGallery')), findsOneWidget);
    expect(find.byKey(const Key('AvatarStatus')), findsOneWidget);
    expect(myUserService.myUser.value?.gallery, isNotEmpty);

    await tester.tap(find.byKey(const Key('AvatarStatus')));
    await mockNetworkImagesFor(
        () async => await tester.pumpAndSettle(const Duration(seconds: 2)));
    expect(myUserService.myUser.value?.avatar?.galleryItemId,
        const GalleryItemId('testId'));
    expect(myUserService.myUser.value?.callCover?.galleryItemId,
        const GalleryItemId('testId'));

    await tester.tap(find.byKey(const Key('AvatarStatus')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(myUserService.myUser.value?.avatar?.galleryItemId, isNull);
    expect(myUserService.myUser.value?.callCover?.galleryItemId, isNull);

    await tester.tap(find.byKey(const Key('DeleteGallery')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('AlertYesButton')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('DeleteGallery')), findsNothing);
    expect(myUserService.myUser.value?.gallery, isEmpty);

    verifyInOrder([
      graphQlProvider.uploadUserGalleryItem(any),
      graphQlProvider.updateUserAvatar(const GalleryItemId('testId'), null),
      graphQlProvider.updateUserCallCover(const GalleryItemId('testId'), null),
      graphQlProvider.updateUserAvatar(null, null),
      graphQlProvider.updateUserCallCover(null, null),
      graphQlProvider.deleteUserGalleryItem(any),
    ]);

    await Get.deleteAll(force: true);
  });
}

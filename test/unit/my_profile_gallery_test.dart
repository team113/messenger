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

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/gallery_item.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/my_user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'my_profile_gallery_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  Hive.init('./test/.temp_hive/my_profile_gallery_unit');
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
    'presence': 'AWAY',
    'online': {'__typename': 'UserOnline'},
  };

  var sessionProvider = SessionDataHiveProvider();
  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  await sessionProvider.init();

  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  await myUserProvider.clear();
  var galleryItemProvider = GalleryItemHiveProvider();
  await galleryItemProvider.init();
  await galleryItemProvider.clear();

  setUp(() async {
    await myUserProvider.clear();
  });

  Get.put(myUserProvider);
  Get.put(galleryItemProvider);
  Get.put(sessionProvider);
  Get.put<GraphQlProvider>(graphQlProvider);

  test(
      'MyUserService successfully adds and removes gallery items, avatar and call cover',
      () async {
    when(graphQlProvider.myUserEvents(null)).thenAnswer(
      (_) => Future.value(Stream.fromIterable([
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'myUserEvents': {'__typename': 'MyUser', ...userData},
          },
        )
      ])),
    );

    when(graphQlProvider.keepOnline())
        .thenAnswer((_) => Future.value(const Stream.empty()));

    when(graphQlProvider.uploadUserGalleryItem(any)).thenAnswer(
      (_) => Future.value(UploadUserGalleryItem$Mutation.fromJson({
        'uploadUserGalleryItem': {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserGalleryItemAdded',
              'userId': 'id',
              'galleryItem': {
                '__typename': 'ImageGalleryItem',
                'id': 'testId',
                'square': 'ug.square.jpg',
                'original': 'orig.png',
                'addedAt': DateTime.now().toString()
              },
              'at': DateTime.now().toString()
            }
          ],
          'myUser': userData,
          'ver':
              '${(myUserProvider.myUser?.ver.internal ?? BigInt.zero + BigInt.one)}',
        }
      }).uploadUserGalleryItem as MyUserEventsVersionedMixin),
    );

    when(graphQlProvider.deleteUserGalleryItem(const GalleryItemId('testId')))
        .thenAnswer(
      (_) => Future.value(DeleteUserGalleryItem$Mutation.fromJson({
        'deleteUserGalleryItem': {
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
          'ver':
              '${(myUserProvider.myUser?.ver.internal ?? BigInt.zero + BigInt.one)}',
        }
      }).deleteUserGalleryItem),
    );

    when(graphQlProvider.updateUserAvatar(const GalleryItemId('testId'), any))
        .thenAnswer(
      (_) => Future.value(UpdateUserAvatar$Mutation.fromJson({
        'updateUserAvatar': {
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
                'vertical': 'cc.vertical.jpg',
                'square': 'cc.square.jpg'
              },
              'at': DateTime.now().toString()
            }
          ],
          'myUser': userData,
          'ver':
              '${(myUserProvider.myUser?.ver.internal ?? BigInt.zero + BigInt.one)}',
        }
      }).updateUserAvatar as MyUserEventsVersionedMixin?),
    );

    when(graphQlProvider.updateUserCallCover(
            const GalleryItemId('testId'), any))
        .thenAnswer(
      (_) => Future.value(UpdateUserAvatar$Mutation.fromJson({
        'updateUserAvatar': {
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
          'ver':
              '${(myUserProvider.myUser?.ver.internal ?? BigInt.zero + BigInt.one)}',
        }
      }).updateUserAvatar as MyUserEventsVersionedMixin?),
    );

    when(graphQlProvider.updateUserAvatar(null, any)).thenAnswer(
      (_) => Future.value(UpdateUserAvatar$Mutation.fromJson({
        'updateUserAvatar': {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserAvatarDeleted',
              'userId': 'id',
              'at': DateTime.now().toString()
            }
          ],
          'myUser': userData,
          'ver':
              '${(myUserProvider.myUser?.ver.internal ?? BigInt.zero + BigInt.one)}',
        }
      }).updateUserAvatar as MyUserEventsVersionedMixin?),
    );

    when(graphQlProvider.updateUserCallCover(null, any)).thenAnswer(
      (_) => Future.value(UpdateUserAvatar$Mutation.fromJson({
        'updateUserAvatar': {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserCallCoverDeleted',
              'userId': 'id',
              'at': DateTime.now().toString()
            }
          ],
          'myUser': userData,
          'ver':
              '${(myUserProvider.myUser?.ver.internal ?? BigInt.zero + BigInt.one)}',
        }
      }).updateUserAvatar as MyUserEventsVersionedMixin?),
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    AbstractMyUserRepository myUserRepository =
        MyUserRepository(graphQlProvider, myUserProvider, galleryItemProvider);
    await myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
    MyUserService myUserService = MyUserService(authService, myUserRepository);

    await myUserService.uploadGalleryItem(
      NativeFile(
        bytes: Uint8List.fromList([1, 1]),
        size: 2,
        name: 'test',
      ),
    );
    await myUserService.updateAvatar(const GalleryItemId('testId'));
    await myUserService.updateCallCover(const GalleryItemId('testId'));
    await myUserService.updateAvatar(null);
    await myUserService.updateCallCover(null);
    await myUserService.deleteGalleryItem(const GalleryItemId('testId'));

    verifyInOrder([
      graphQlProvider.uploadUserGalleryItem(any),
      graphQlProvider.updateUserAvatar(const GalleryItemId('testId'), null),
      graphQlProvider.updateUserCallCover(const GalleryItemId('testId'), null),
      graphQlProvider.updateUserAvatar(null, null),
      graphQlProvider.updateUserCallCover(null, null),
      graphQlProvider.deleteUserGalleryItem(const GalleryItemId('testId')),
    ]);
  });

  test(
      'MyUserService throws UploadUserGalleryItemException, UpdateUserAvatarException, UpdateUserCallCoverException',
      () async {
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

    when(graphQlProvider.uploadUserGalleryItem(any)).thenThrow(
        UploadUserGalleryItemException(
            UploadUserGalleryItemErrorCode.tooBigSize));

    when(graphQlProvider.updateUserAvatar(any, any)).thenThrow(
        UpdateUserAvatarException(
            UpdateUserAvatarErrorCode.unknownGalleryItem));

    when(graphQlProvider.updateUserCallCover(any, any)).thenThrow(
        UpdateUserCallCoverException(
            UpdateUserCallCoverErrorCode.unknownGalleryItem));

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    AbstractMyUserRepository myUserRepository =
        MyUserRepository(graphQlProvider, myUserProvider, galleryItemProvider);
    await myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
    MyUserService myUserService = MyUserService(authService, myUserRepository);

    expect(
      () async => await myUserService.uploadGalleryItem(
        NativeFile(
          bytes: Uint8List.fromList([1, 1]),
          size: 2,
          name: 'test',
        ),
      ),
      throwsA(isA<UploadUserGalleryItemException>()),
    );

    expect(
      () async =>
          await myUserService.updateAvatar(const GalleryItemId('testId')),
      throwsA(isA<UpdateUserAvatarException>()),
    );

    expect(
      () async =>
          await myUserService.updateCallCover(const GalleryItemId('testId')),
      throwsA(isA<UpdateUserCallCoverException>()),
    );

    verifyInOrder([
      graphQlProvider.uploadUserGalleryItem(any),
      graphQlProvider.updateUserAvatar(const GalleryItemId('testId'), null),
      graphQlProvider.updateUserCallCover(const GalleryItemId('testId'), null),
    ]);
  });
}

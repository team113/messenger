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
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'my_profile_emails_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  Hive.init('./test/.temp_hive/my_profile_emails_unit');
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
  var userProvider = UserHiveProvider();
  await userProvider.init();

  setUp(() async {
    await myUserProvider.clear();
  });

  Get.put(myUserProvider);
  Get.put(galleryItemProvider);
  Get.put<GraphQlProvider>(graphQlProvider);
  Get.put(sessionProvider);

  test(
      'MyUserService successfully adds, removes, confirms email and resends confirmation code',
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

    when(graphQlProvider.addUserEmail(UserEmail('test@mail.ru'))).thenAnswer(
      (_) => Future.value(AddUserEmail$Mutation.fromJson({
        'addUserEmail': {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserEmailAdded',
              'userId': 'id',
              'email': 'test@mail.ru',
              'at': DateTime.now().toString(),
            }
          ],
          'myUser': userData,
          'ver':
              '${(myUserProvider.myUser?.ver.internal ?? BigInt.zero + BigInt.one)}',
        }
      }).addUserEmail
          as AddUserEmail$Mutation$AddUserEmail$MyUserEventsVersioned),
    );

    when(graphQlProvider.resendEmail()).thenAnswer((_) => Future.value());
    when(graphQlProvider.keepOnline())
        .thenAnswer((_) => Future.value(const Stream.empty()));

    when(graphQlProvider.confirmEmailCode(ConfirmationCode('1234'))).thenAnswer(
      (_) => Future.value(ConfirmUserEmail$Mutation.fromJson({
        'confirmUserEmail': {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserEmailConfirmed',
              'userId': 'id',
              'email': 'test@mail.ru',
              'at': DateTime.now().toString(),
            }
          ],
          'myUser': userData,
          'ver': '${(myUserProvider.myUser!.ver.internal + BigInt.one)}',
        }
      }).confirmUserEmail
          as ConfirmUserEmail$Mutation$ConfirmUserEmail$MyUserEventsVersioned),
    );

    when(graphQlProvider.deleteUserEmail(UserEmail('test@mail.ru'))).thenAnswer(
      (_) => Future.value(DeleteUserEmail$Mutation.fromJson({
        'deleteUserEmail': {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserEmailDeleted',
              'userId': 'id',
              'email': 'test@mail.ru',
              'at': DateTime.now().toString(),
            }
          ],
          'myUser': userData,
          'ver': '${(myUserProvider.myUser!.ver.internal + BigInt.one)}',
        }
      }).deleteUserEmail),
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractMyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      galleryItemProvider,
      userRepository,
    );
    await myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
    MyUserService myUserService = MyUserService(authService, myUserRepository);

    await myUserService.addUserEmail(UserEmail('test@mail.ru'));
    await myUserService.resendEmail();
    await myUserService.confirmEmailCode(ConfirmationCode('1234'));
    await myUserService.deleteUserEmail(UserEmail('test@mail.ru'));

    verifyInOrder([
      graphQlProvider.addUserEmail(UserEmail('test@mail.ru')),
      graphQlProvider.resendEmail(),
      graphQlProvider.confirmEmailCode(ConfirmationCode('1234')),
      graphQlProvider.deleteUserEmail(UserEmail('test@mail.ru'))
    ]);
  });

  test(
      'MyUserService throws AddUserEmailException, ResendUserEmailConfirmationException, ConfirmUserEmailException',
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

    when(graphQlProvider.addUserEmail(UserEmail('test@mail.ru')))
        .thenThrow(const AddUserEmailException(AddUserEmailErrorCode.tooMany));

    when(graphQlProvider.resendEmail()).thenThrow(
        const ResendUserEmailConfirmationException(
            ResendUserEmailConfirmationErrorCode.codeLimitExceeded));

    when(graphQlProvider.confirmEmailCode(ConfirmationCode('1234'))).thenThrow(
        const ConfirmUserEmailException(ConfirmUserEmailErrorCode.wrongCode));

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractMyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      galleryItemProvider,
      userRepository,
    );
    await myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
    MyUserService myUserService = MyUserService(authService, myUserRepository);

    expect(
        () async => await myUserService.addUserEmail(UserEmail('test@mail.ru')),
        throwsA(isA<AddUserEmailException>()));

    expect(() async => await myUserService.resendEmail(),
        throwsA(isA<ResendUserEmailConfirmationException>()));

    expect(
        () async =>
            await myUserService.confirmEmailCode(ConfirmationCode('1234')),
        throwsA(isA<ConfirmUserEmailException>()));

    verifyInOrder([
      graphQlProvider.addUserEmail(UserEmail('test@mail.ru')),
      graphQlProvider.resendEmail(),
      graphQlProvider.confirmEmailCode(ConfirmationCode('1234')),
    ]);
  });
}

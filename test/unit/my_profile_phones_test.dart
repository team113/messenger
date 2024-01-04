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
import 'package:messenger/provider/hive/blocklist.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/credentials.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/blocklist.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'my_profile_phones_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  Hive.init('./test/.temp_hive/my_profile_phones_unit');
  var myUserData = {
    'id': '12345',
    'num': '1234567890123456',
    'login': 'login',
    'name': 'name',
    'emails': {'confirmed': [], 'unconfirmed': null},
    'phones': {'confirmed': [], 'unconfirmed': null},
    'hasPassword': true,
    'unreadChatsCount': 0,
    'ver': '0',
    'presence': 'AWAY',
    'online': {'__typename': 'UserOnline'},
    'blocklist': {'totalCount': 0},
  };

  var blocklist = {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    }
  };

  var credentialsProvider = CredentialsHiveProvider();
  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  await credentialsProvider.init();

  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  await myUserProvider.clear();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  var blockedUsersProvider = BlocklistHiveProvider();
  await blockedUsersProvider.init();

  setUp(() async {
    await myUserProvider.clear();
  });

  Get.put(myUserProvider);
  Get.put<GraphQlProvider>(graphQlProvider);
  Get.put(credentialsProvider);

  test(
      'MyUserService successfully adds, removes, confirms phone and resends confirmation code',
      () async {
    when(graphQlProvider.myUserEvents(any)).thenAnswer(
      (_) => Stream.fromIterable([
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'myUserEvents': {'__typename': 'MyUser', ...myUserData},
          },
        )
      ]),
    );

    when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

    when(graphQlProvider.addUserPhone(UserPhone('+380999999999'))).thenAnswer(
      (_) => Future.value(AddUserPhone$Mutation.fromJson({
        'addUserPhone': {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserPhoneAdded',
              'userId': 'id',
              'phone': '+380999999999',
              'at': DateTime.now().toString(),
            }
          ],
          'myUser': myUserData,
          'ver':
              '${(myUserProvider.myUser?.ver.internal ?? BigInt.zero + BigInt.one)}',
        }
      }).addUserPhone
          as AddUserPhone$Mutation$AddUserPhone$MyUserEventsVersioned),
    );

    when(graphQlProvider.resendPhone()).thenAnswer((_) => Future.value());

    when(graphQlProvider.confirmPhoneCode(ConfirmationCode('1234'))).thenAnswer(
      (_) => Future.value(ConfirmUserPhone$Mutation.fromJson({
        'confirmUserPhone': {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserPhoneConfirmed',
              'userId': 'id',
              'phone': '+380999999999',
              'at': DateTime.now().toString(),
            }
          ],
          'myUser': myUserData,
          'ver': '${(myUserProvider.myUser!.ver.internal + BigInt.one)}',
        }
      }).confirmUserPhone
          as ConfirmUserPhone$Mutation$ConfirmUserPhone$MyUserEventsVersioned),
    );

    when(graphQlProvider.deleteUserPhone(UserPhone('+380999999999')))
        .thenAnswer(
      (_) => Future.value(DeleteUserPhone$Mutation.fromJson({
        'deleteUserPhone': {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {
              '__typename': 'EventUserPhoneDeleted',
              'userId': 'id',
              'phone': '+380999999999',
              'at': DateTime.now().toString(),
            }
          ],
          'myUser': myUserData,
          'ver': '${(myUserProvider.myUser!.ver.internal + BigInt.one)}',
        }
      }).deleteUserPhone),
    );

    when(graphQlProvider.getBlocklist(
      first: anyNamed('first'),
      after: null,
      last: null,
      before: null,
    )).thenAnswer(
      (_) => Future.value(GetBlocklist$Query$Blocklist.fromJson(blocklist)),
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        credentialsProvider,
      ),
    );
    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));

    BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
          graphQlProvider, blockedUsersProvider, userRepository),
    );

    AbstractMyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      blocklistRepository,
      userRepository,
    );
    myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
    await Future.delayed(Duration.zero);

    MyUserService myUserService = MyUserService(authService, myUserRepository);

    await myUserService.addUserPhone(UserPhone('+380999999999'));
    await myUserService.resendPhone();
    await myUserService.confirmPhoneCode(ConfirmationCode('1234'));
    await myUserService.deleteUserPhone(UserPhone('+380999999999'));

    verifyInOrder([
      graphQlProvider.addUserPhone(UserPhone('+380999999999')),
      graphQlProvider.resendPhone(),
      graphQlProvider.confirmPhoneCode(ConfirmationCode('1234')),
      graphQlProvider.deleteUserPhone(UserPhone('+380999999999'))
    ]);
  });

  test(
      'MyUserService throws AddUserPhoneException, ResendUserPhoneConfirmationErrorCode, ConfirmUserPhoneException',
      () async {
    when(graphQlProvider.myUserEvents(any)).thenAnswer(
      (_) => Stream.fromIterable([
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'myUserEvents': {'__typename': 'MyUser', ...myUserData},
          },
        ),
      ]),
    );

    when(
      graphQlProvider.addUserPhone(UserPhone('+380999999999')),
    ).thenThrow(
      const AddUserPhoneException(AddUserPhoneErrorCode.tooMany),
    );

    when(
      graphQlProvider.resendPhone(),
    ).thenThrow(const ResendUserPhoneConfirmationException(
      ResendUserPhoneConfirmationErrorCode.codeLimitExceeded,
    ));

    when(graphQlProvider.confirmPhoneCode(ConfirmationCode('1234'))).thenThrow(
        const ConfirmUserPhoneException(ConfirmUserPhoneErrorCode.wrongCode));

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        credentialsProvider,
      ),
    );
    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));

    BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
          graphQlProvider, blockedUsersProvider, userRepository),
    );

    AbstractMyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      blocklistRepository,
      userRepository,
    );
    myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
    MyUserService myUserService = MyUserService(authService, myUserRepository);

    expect(
      () async => await myUserService.addUserPhone(UserPhone('+380999999999')),
      throwsA(isA<AddUserPhoneException>()),
    );

    expect(
      () async => await myUserService.resendPhone(),
      throwsA(isA<ResendUserPhoneConfirmationException>()),
    );

    expect(
        () async =>
            await myUserService.confirmPhoneCode(ConfirmationCode('1234')),
        throwsA(isA<ConfirmUserPhoneException>()));

    verifyInOrder([
      graphQlProvider.addUserPhone(UserPhone('+380999999999')),
      graphQlProvider.resendPhone(),
      graphQlProvider.confirmPhoneCode(ConfirmationCode('1234')),
    ]);
  });
}

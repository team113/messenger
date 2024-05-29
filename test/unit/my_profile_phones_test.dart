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
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/my_user.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/account.dart';
import 'package:messenger/provider/hive/blocklist.dart';
import 'package:messenger/provider/hive/blocklist_sorting.dart';
import 'package:messenger/provider/hive/credentials.dart';
import 'package:messenger/provider/hive/session_data.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/blocklist.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'my_profile_phones_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  Hive.init('./test/.temp_hive/my_profile_phones_unit');

  var credentialsProvider = CredentialsHiveProvider();
  await credentialsProvider.init();

  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  await credentialsProvider.init();

  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final userProvider = UserDriftProvider(common, scoped);
  var blockedUsersProvider = BlocklistHiveProvider();
  await blockedUsersProvider.init();
  var sessionProvider = SessionDataHiveProvider();
  await sessionProvider.init();
  var blocklistSortingProvider = BlocklistSortingHiveProvider();
  await blocklistSortingProvider.init();
  final accountProvider = AccountHiveProvider();
  await accountProvider.init();

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
      (_) async => Stream.fromIterable([
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
      (_) async => AddUserPhone$Mutation.fromJson({
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
              '${((await myUserProvider.accounts()).firstOrNull?.ver.internal ?? BigInt.zero + BigInt.one)}',
        }
      }).addUserPhone
          as AddUserPhone$Mutation$AddUserPhone$MyUserEventsVersioned,
    );

    when(graphQlProvider.resendPhone()).thenAnswer((_) => Future.value());

    when(graphQlProvider.confirmPhoneCode(ConfirmationCode('1234'))).thenAnswer(
      (_) async => ConfirmUserPhone$Mutation.fromJson({
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
          'ver':
              '${((await myUserProvider.accounts()).first.ver.internal + BigInt.one)}',
        }
      }).confirmUserPhone
          as ConfirmUserPhone$Mutation$ConfirmUserPhone$MyUserEventsVersioned,
    );

    when(graphQlProvider.deleteUserPhone(UserPhone('+380999999999')))
        .thenAnswer(
      (_) async => DeleteUserPhone$Mutation.fromJson({
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
          'ver':
              '${((await myUserProvider.accounts()).first.ver.internal + BigInt.one)}',
        }
      }).deleteUserPhone,
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
        Get.put<AbstractAuthRepository>(AuthRepository(
          Get.find(),
          myUserProvider,
          credentialsProvider,
        )),
        credentialsProvider,
        accountProvider,
      ),
    );
    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));

    BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
        graphQlProvider,
        blockedUsersProvider,
        blocklistSortingProvider,
        userRepository,
        sessionProvider,
      ),
    );

    AbstractMyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      blocklistRepository,
      userRepository,
      accountProvider,
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
      (_) async => Stream.fromIterable([
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
        Get.put<AbstractAuthRepository>(AuthRepository(
          Get.find(),
          myUserProvider,
          credentialsProvider,
        )),
        credentialsProvider,
        accountProvider,
      ),
    );
    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));

    BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
        graphQlProvider,
        blockedUsersProvider,
        blocklistSortingProvider,
        userRepository,
        sessionProvider,
      ),
    );

    AbstractMyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      blocklistRepository,
      userRepository,
      accountProvider,
    );
    myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
    MyUserService myUserService = MyUserService(authService, myUserRepository);
    await Future.delayed(Duration.zero);

    await expectLater(
      () async => await myUserService.addUserPhone(UserPhone('+380999999999')),
      throwsA(isA<AddUserPhoneException>()),
    );

    await expectLater(
      () async => await myUserService.resendPhone(),
      throwsA(isA<ResendUserPhoneConfirmationException>()),
    );

    await expectLater(
        () async =>
            await myUserService.confirmPhoneCode(ConfirmationCode('1234')),
        throwsA(isA<ConfirmUserPhoneException>()));

    verifyInOrder([
      graphQlProvider.addUserPhone(UserPhone('+380999999999')),
      graphQlProvider.resendPhone(),
      graphQlProvider.confirmPhoneCode(ConfirmationCode('1234')),
    ]);
  });

  tearDown(() async => await Future.wait([common.close(), scoped.close()]));
}

final myUserData = {
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

final blocklist = {
  'edges': [],
  'pageInfo': {
    'endCursor': 'endCursor',
    'hasNextPage': false,
    'startCursor': 'startCursor',
    'hasPreviousPage': false,
  }
};

// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:graphql/client.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/drift/account.dart';
import 'package:messenger/provider/drift/blocklist.dart';
import 'package:messenger/provider/drift/credentials.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/locks.dart';
import 'package:messenger/provider/drift/my_user.dart';
import 'package:messenger/provider/drift/secret.dart';
import 'package:messenger/provider/drift/slugs.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/drift/version.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/blocklist.dart';
import 'package:messenger/store/model/my_user.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'my_profile_emails_test.mocks.dart';

@GenerateNiceMocks([MockSpec<GraphQlProvider>()])
void main() async {
  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(
    graphQlProvider.onStart,
  ).thenReturn(InternalFinalCallback(callback: () {}));

  final credentialsProvider = Get.put(CredentialsDriftProvider(common));
  final accountProvider = Get.put(AccountDriftProvider(common));
  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final userProvider = UserDriftProvider(common, scoped);
  final blocklistProvider = Get.put(BlocklistDriftProvider(common, scoped));
  final versionProvider = Get.put(VersionDriftProvider(common));
  final locksProvider = Get.put(LockDriftProvider(common));
  final secretsProvider = Get.put(RefreshSecretDriftProvider(common));
  final slugProvider = Get.put(SlugDriftProvider(common));

  setUp(() async {
    await myUserProvider.clear();
  });

  Get.put(myUserProvider);
  Get.put<GraphQlProvider>(graphQlProvider);
  Get.put(credentialsProvider);

  test(
    'MyUserService successfully adds, removes, confirms email and resends confirmation code',
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
        graphQlProvider.addUserEmail(UserEmail('test@dummy.com')),
      ).thenAnswer(
        (_) async =>
            AddUserEmail$Mutation.fromJson({
                  'addUserEmail': {
                    '__typename': 'MyUserEventsVersioned',
                    'events': [
                      {
                        '__typename': 'EventUserEmailAdded',
                        'userId': 'id',
                        'email': 'test@dummy.com',
                        'confirmed': false,
                        'at': DateTime.now().toString(),
                      },
                    ],
                    'myUser': myUserData,
                    'ver': '${((await myUserProvider.accounts()).first.ver)}',
                  },
                }).addUserEmail
                as AddUserEmail$Mutation$AddUserEmail$MyUserEventsVersioned,
      );

      when(
        graphQlProvider.addUserEmail(
          UserEmail('test@dummy.com'),
          confirmation: ConfirmationCode('1234'),
        ),
      ).thenAnswer(
        (_) async =>
            AddUserEmail$Mutation.fromJson({
                  'addUserEmail': {
                    '__typename': 'MyUserEventsVersioned',
                    'events': [
                      {
                        '__typename': 'EventUserEmailAdded',
                        'userId': 'id',
                        'email': 'test@dummy.com',
                        'confirmed': true,
                        'at': DateTime.now().toString(),
                      },
                    ],
                    'myUser': myUserData,
                    'ver':
                        '${MyUserVersion(('${(await myUserProvider.accounts()).first.ver.val}A'))}',
                  },
                }).addUserEmail
                as AddUserEmail$Mutation$AddUserEmail$MyUserEventsVersioned,
      );

      when(
        graphQlProvider.keepOnline(),
      ).thenAnswer((_) => const Stream.empty());
      when(
        graphQlProvider.sessionsEvents(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        graphQlProvider.blocklistEvents(any),
      ).thenAnswer((_) => const Stream.empty());

      when(graphQlProvider.signUp()).thenAnswer(
        (_) => Future.value(
          SignUp$Mutation$CreateUser$CreateSessionOk.fromJson({
            'session': {
              '__typename': 'Session',
              'id': '1ba588ce-d084-486d-9087-3999c8f56596',
              'ip': '127.0.0.1',
              'userAgent':
                  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
              'isCurrent': true,
              'lastActivatedAt': DateTime.now().toString(),
              'ver': '031592915314290362597742826064324903711',
              'siteDomain': 'example.com',
            },
            'accessToken': {
              '__typename': 'AccessToken',
              'secret': 'token',
              'expiresAt': DateTime.now()
                  .add(const Duration(days: 1))
                  .toString(),
            },
            'refreshToken': {
              '__typename': 'RefreshToken',
              'secret': 'token',
              'expiresAt': DateTime.now()
                  .add(const Duration(days: 1))
                  .toString(),
            },
            'user': myUserData,
          }),
        ),
      );

      when(
        graphQlProvider.removeUserEmail(UserEmail('test@dummy.com')),
      ).thenAnswer(
        (_) async =>
            RemoveUserEmail$Mutation.fromJson({
                  'removeUserEmail': {
                    '__typename': 'MyUserEventsVersioned',
                    'events': [
                      {
                        '__typename': 'EventUserEmailRemoved',
                        'userId': 'id',
                        'email': 'test@dummy.com',
                        'at': DateTime.now().toString(),
                      },
                    ],
                    'myUser': myUserData,
                    'ver':
                        '${MyUserVersion(('${(await myUserProvider.accounts()).first.ver.val}A'))}',
                  },
                }).removeUserEmail
                as RemoveUserEmail$Mutation$RemoveUserEmail$MyUserEventsVersioned,
      );

      when(
        graphQlProvider.keepOnline(),
      ).thenAnswer((_) => const Stream.empty());
      when(
        graphQlProvider.sessionsEvents(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        graphQlProvider.blocklistEvents(any),
      ).thenAnswer((_) => const Stream.empty());

      AuthService authService = Get.put(
        AuthService(
          Get.put<AbstractAuthRepository>(
            AuthRepository(
              Get.find(),
              myUserProvider,
              credentialsProvider,
              slugProvider,
            ),
          ),
          credentialsProvider,
          accountProvider,
          locksProvider,
          secretsProvider,
        ),
      );
      await authService.init();

      UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, me: const UserId('me')),
      );

      BlocklistRepository blocklistRepository = Get.put(
        BlocklistRepository(
          graphQlProvider,
          blocklistProvider,
          userRepository,
          versionProvider,
          me: const UserId('me'),
        ),
      );

      AbstractMyUserRepository myUserRepository = MyUserRepository(
        graphQlProvider,
        myUserProvider,
        blocklistRepository,
        userRepository,
        accountProvider,
        me: const UserId('me'),
      );

      await myUserRepository.init(
        onUserDeleted: () {},
        onPasswordUpdated: () {},
      );

      await Future.delayed(Duration.zero);

      MyUserService myUserService = MyUserService(
        authService,
        myUserRepository,
      );

      await authService.register();

      await myUserService.addUserEmail(UserEmail('test@dummy.com'));
      await myUserService.addUserEmail(
        UserEmail('test@dummy.com'),
        confirmation: ConfirmationCode('1234'),
      );
      await myUserService.removeUserEmail(UserEmail('test@dummy.com'));

      verifyInOrder([
        graphQlProvider.addUserEmail(UserEmail('test@dummy.com')),
        graphQlProvider.addUserEmail(
          UserEmail('test@dummy.com'),
          confirmation: ConfirmationCode('1234'),
        ),
        graphQlProvider.removeUserEmail(UserEmail('test@dummy.com')),
      ]);
    },
  );

  test(
    'MyUserService throws AddUserEmailException, ResendUserEmailConfirmationException, ConfirmUserEmailException',
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
        graphQlProvider.sessionsEvents(any),
      ).thenAnswer((_) => const Stream.empty());

      when(
        graphQlProvider.addUserEmail(UserEmail('test@dummy.com')),
      ).thenThrow(const AddUserEmailException(AddUserEmailErrorCode.tooMany));

      when(
        graphQlProvider.addUserEmail(
          UserEmail('test@dummy.com'),
          confirmation: ConfirmationCode('1234'),
        ),
      ).thenThrow(const AddUserEmailException(AddUserEmailErrorCode.wrongCode));

      AuthService authService = Get.put(
        AuthService(
          Get.put<AbstractAuthRepository>(
            AuthRepository(
              Get.find(),
              myUserProvider,
              credentialsProvider,
              slugProvider,
            ),
          ),
          credentialsProvider,
          accountProvider,
          locksProvider,
          secretsProvider,
        ),
      );
      UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, me: const UserId('me')),
      );

      BlocklistRepository blocklistRepository = Get.put(
        BlocklistRepository(
          graphQlProvider,
          blocklistProvider,
          userRepository,
          versionProvider,
          me: const UserId('me'),
        ),
      );

      final AbstractMyUserRepository myUserRepository = MyUserRepository(
        graphQlProvider,
        myUserProvider,
        blocklistRepository,
        userRepository,
        accountProvider,
        me: const UserId('me'),
      );
      myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
      final MyUserService myUserService = MyUserService(
        authService,
        myUserRepository,
      );
      await Future.delayed(Duration.zero);

      await expectLater(
        () async =>
            await myUserService.addUserEmail(UserEmail('test@dummy.com')),
        throwsA(isA<AddUserEmailException>()),
      );

      await expectLater(
        () async => await myUserService.addUserEmail(
          UserEmail('test@dummy.com'),
          confirmation: ConfirmationCode('1234'),
        ),
        throwsA(isA<AddUserEmailException>()),
      );

      verifyInOrder([
        graphQlProvider.addUserEmail(UserEmail('test@dummy.com')),
        graphQlProvider.addUserEmail(
          UserEmail('test@dummy.com'),
          confirmation: ConfirmationCode('1234'),
        ),
      ]);
    },
  );

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
  },
};

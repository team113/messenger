// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/provider/drift/account.dart';
import 'package:messenger/provider/drift/credentials.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/locks.dart';
import 'package:messenger/provider/drift/my_user.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_test.mocks.dart';

@GenerateNiceMocks([MockSpec<GraphQlProvider>()])
void main() async {
  final CommonDriftProvider common = Get.put(
    CommonDriftProvider.memory(),
    permanent: true,
  );

  Get.put(ScopedDriftProvider.memory(), permanent: true);

  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final credsProvider = Get.put(CredentialsDriftProvider(common));
  final accountProvider = Get.put(AccountDriftProvider(common));
  final locksProvider = Get.put(LockDriftProvider(common));

  setUp(() async {
    Get.reset();
    await credsProvider.clear();
    await accountProvider.clear();
  });

  test('AuthService successfully logins with no session saved', () async {
    final getStorage = credsProvider;
    final graphQlProvider = MockGraphQlProvider();
    when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

    when(
      graphQlProvider.signIn(
        credentials: MyUserCredentials(password: UserPassword('123')),
        identifier: MyUserIdentifier(login: UserLogin('user')),
      ),
    ).thenAnswer(
      (_) => Future.value(
        SignIn$Mutation$CreateSession$CreateSessionOk.fromJson({
          'session': {
            '__typename': 'Session',
            'id': '1ba588ce-d084-486d-9087-3999c8f56596',
            'ip': '127.0.0.1',
            'userAgent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
            'isCurrent': true,
            'lastActivatedAt': DateTime.now().toString(),
            'ver': '031592915314290362597742826064324903711',
          },
          'accessToken': {
            '__typename': 'AccessToken',
            'secret': 'token',
            'expiresAt': DateTime.now().add(const Duration(days: 1)).toString(),
          },
          'refreshToken': {
            '__typename': 'RefreshToken',
            'secret': 'token',
            'expiresAt': DateTime.now().add(const Duration(days: 1)).toString(),
          },
          'user': {
            '__typename': 'MyUser',
            'id': 'id',
            'num': '1234567890123456',
            'login': 'val',
            'name': 'name',
            'emails': {'confirmed': []},
            'phones': {'confirmed': []},
            'hasPassword': true,
            'unreadChatsCount': 0,
            'ver': '30066501444801094020394372057490153134',
            'presence': 'AWAY',
            'online': {'__typename': 'UserOnline'},
          },
        }),
      ),
    );

    AuthRepository authRepository = Get.put(
      AuthRepository(graphQlProvider, myUserProvider, credsProvider),
    );
    AuthService authService = Get.put(
      AuthService(authRepository, getStorage, accountProvider, locksProvider),
    );

    router = RouterState(authService);

    expect(await authService.init(), Routes.auth);

    await authService.signIn(
      password: UserPassword('123'),
      login: UserLogin('user'),
    );

    expect(authService.status.value.isSuccess, true);
    expect(
      authService.credentials.value?.access.secret,
      const AccessTokenSecret('token'),
    );

    await authService.logout();

    expect(authService.status.value.isEmpty, true);
    verify(
      graphQlProvider.signIn(
        credentials: MyUserCredentials(password: UserPassword('123')),
        identifier: MyUserIdentifier(login: UserLogin('user')),
      ),
    );
  });

  test('AuthService successfully logins with saved session', () async {
    await accountProvider.upsert(const UserId('me'));
    await credsProvider.upsert(
      Credentials(
        AccessToken(
          const AccessTokenSecret('token'),
          PreciseDateTime.now().add(const Duration(days: 1)),
        ),
        RefreshToken(
          const RefreshTokenSecret('token'),
          PreciseDateTime.now().add(const Duration(days: 1)),
        ),
        Session(
          id: const SessionId('me'),
          ip: IpAddress('localhost'),
          userAgent: UserAgent(''),
          lastActivatedAt: PreciseDateTime.now(),
        ),
        const UserId('me'),
      ),
    );
    final graphQlProvider = MockGraphQlProvider();
    when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

    AuthRepository authRepository = Get.put(
      AuthRepository(graphQlProvider, myUserProvider, credsProvider),
    );
    AuthService authService = Get.put(
      AuthService(
        authRepository,
        credsProvider,
        accountProvider,
        locksProvider,
      ),
    );

    router = RouterState(authService);

    expect(await authService.init(), null);

    expect(authService.status.value.isSuccess, true);
    expect(
      authService.credentials.value?.access.secret,
      const AccessTokenSecret('token'),
    );

    await authService.logout();

    expect(authService.status.value.isEmpty, true);
    expect(authService.credentials.value, null);
  });

  test('AuthService throws an Exception at null username', () async {
    final graphQlProvider = MockGraphQlProvider();
    when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

    when(
      graphQlProvider.signIn(
        credentials: MyUserCredentials(password: UserPassword('123')),
        identifier: MyUserIdentifier(),
      ),
    ).thenThrow(
      const CreateSessionException((CreateSessionErrorCode.wrongPassword)),
    );

    final AuthRepository authRepository = Get.put(
      AuthRepository(graphQlProvider, myUserProvider, credsProvider),
    );
    final AuthService authService = Get.put(
      AuthService(
        authRepository,
        credsProvider,
        accountProvider,
        locksProvider,
      ),
    );

    router = RouterState(authService);

    expect(await authService.init(), Routes.auth);
    try {
      await authService.signIn(password: UserPassword('123'));
      fail('Exception is not thrown');
    } catch (e) {
      expect(e, isA<CreateSessionException>());
    }

    verify(
      graphQlProvider.signIn(
        credentials: MyUserCredentials(password: UserPassword('123')),
        identifier: MyUserIdentifier(),
      ),
    );
  });

  test('AuthService successfully resets password', () async {
    final graphQlProvider = MockGraphQlProvider();
    when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

    AuthRepository authRepository = Get.put(
      AuthRepository(graphQlProvider, myUserProvider, credsProvider),
    );
    AuthService authService = Get.put(
      AuthService(
        authRepository,
        credsProvider,
        accountProvider,
        locksProvider,
      ),
    );

    when(
      graphQlProvider.createConfirmationCode(
        MyUserIdentifier(login: UserLogin('login')),
      ),
    ).thenAnswer((_) => Future.value());

    when(
      graphQlProvider.updateUserPassword(
        identifier: MyUserIdentifier(login: UserLogin('login')),
        confirmation: MyUserCredentials(code: ConfirmationCode('1234')),
        newPassword: UserPassword('123456'),
      ),
    ).thenAnswer((_) => Future.value());

    await authService.createConfirmationCode(login: UserLogin('login'));
    await authService.updateUserPassword(
      login: UserLogin('login'),
      code: ConfirmationCode('1234'),
      newPassword: UserPassword('123456'),
    );

    verifyInOrder([
      graphQlProvider.createConfirmationCode(
        MyUserIdentifier(login: UserLogin('login')),
      ),
      graphQlProvider.updateUserPassword(
        identifier: MyUserIdentifier(login: UserLogin('login')),
        confirmation: MyUserCredentials(code: ConfirmationCode('1234')),
        newPassword: UserPassword('123456'),
      ),
    ]);
  });

  test('AuthService identifies wrong confirmation code', () async {
    final graphQlProvider = MockGraphQlProvider();
    when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

    AuthRepository authRepository = Get.put(
      AuthRepository(graphQlProvider, myUserProvider, credsProvider),
    );
    AuthService authService = Get.put(
      AuthService(
        authRepository,
        credsProvider,
        accountProvider,
        locksProvider,
      ),
    );

    when(
      graphQlProvider.createConfirmationCode(
        MyUserIdentifier(login: UserLogin('login')),
      ),
    ).thenAnswer((_) => Future.value());

    when(
      graphQlProvider.updateUserPassword(
        identifier: MyUserIdentifier(login: UserLogin('login')),
        confirmation: MyUserCredentials(code: ConfirmationCode('1111')),
        newPassword: UserPassword('123456'),
      ),
    ).thenThrow(
      const UpdateUserPasswordException(UpdateUserPasswordErrorCode.wrongCode),
    );

    await authService.createConfirmationCode(login: UserLogin('login'));

    expect(
      () async => await authService.updateUserPassword(
        login: UserLogin('login'),
        code: ConfirmationCode('1111'),
        newPassword: UserPassword('123456'),
      ),
      throwsA(isA<UpdateUserPasswordException>()),
    );

    await Future.delayed(Duration.zero);

    verifyInOrder([
      graphQlProvider.createConfirmationCode(
        MyUserIdentifier(login: UserLogin('login')),
      ),
      graphQlProvider.updateUserPassword(
        identifier: MyUserIdentifier(login: UserLogin('login')),
        confirmation: MyUserCredentials(code: ConfirmationCode('1111')),
        newPassword: UserPassword('123456'),
      ),
    ]);
  });
}

// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  Hive.init('./test/.temp_hive/unit_auth');
  var provider = SessionDataHiveProvider();
  await provider.init();

  setUp(() async {
    Get.reset();
    await provider.clear();
  });

  test('AuthService successfully logins with no session saved', () async {
    final getStorage = provider;
    final graphQlProvider = MockGraphQlProvider();
    when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

    when(graphQlProvider.signIn(
            UserPassword('123'), UserLogin('user'), null, null, null, true))
        .thenAnswer(
      (_) => Future.value(
        SignIn$Mutation$CreateSession$CreateSessionOk.fromJson({
          'session': {
            'token': 'token',
            'expireAt': DateTime.now().add(const Duration(days: 1)).toString(),
            'ver': '30066501444801094020394372057490153134',
          },
          'remembered': {
            'token': 'token',
            'expireAt': DateTime.now().add(const Duration(days: 1)).toString(),
            'ver': '30066501444801094020394372057490153134',
          },
          'user': {
            'id': 'id',
            'num': '1234567890123456',
            'login': 'val',
            'name': 'name',
            'bio': 'bio',
            'emails': {'confirmed': []},
            'phones': {'confirmed': []},
            'gallery': {'nodes': []},
            'hasPassword': true,
            'unreadChatsCount': 0,
            'ver': '30066501444801094020394372057490153134',
            'presence': 'AWAY',
            'online': {'__typename': 'UserOnline'},
          },
        }),
      ),
    );

    AuthRepository authRepository = Get.put(AuthRepository(graphQlProvider));
    AuthService authService = Get.put(AuthService(authRepository, getStorage));

    expect(await authService.init(), Routes.auth);

    await authService.signIn(UserPassword('123'), login: UserLogin('user'));

    expect(authService.status.value.isSuccess, true);
    expect(authService.credentials.value?.session.token,
        const AccessToken('token'));

    await authService.logout();

    expect(authService.status.value.isEmpty, true);
    verify(graphQlProvider.signIn(
        UserPassword('123'), UserLogin('user'), null, null, null, true));
  });

  test('AuthService successfully logins with saved session', () async {
    provider.setCredentials(
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
    final graphQlProvider = MockGraphQlProvider();
    when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

    AuthRepository authRepository = Get.put(AuthRepository(graphQlProvider));
    AuthService authService = Get.put(AuthService(authRepository, provider));

    expect(await authService.init(), null);

    expect(authService.status.value.isSuccess, true);
    expect(authService.credentials.value?.session.token,
        const AccessToken('token'));

    await authService.logout();

    expect(authService.status.value.isEmpty, true);
  });

  test('AuthService throws an Exception at null username', () async {
    final graphQlProvider = MockGraphQlProvider();
    when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

    when(graphQlProvider.signIn(
            UserPassword('123'), null, null, null, null, true))
        .thenThrow(
            const CreateSessionException((CreateSessionErrorCode.unknownUser)));

    AuthRepository authRepository = Get.put(AuthRepository(graphQlProvider));
    AuthService authService = Get.put(AuthService(authRepository, provider));

    expect(await authService.init(), Routes.auth);
    try {
      await authService.signIn(UserPassword('123'));
      fail('Exception is not thrown');
    } catch (e) {
      expect(e, isA<CreateSessionException>());
    }

    verify(graphQlProvider.signIn(
        UserPassword('123'), null, null, null, null, true));
  });

  test('AuthService successfully resets password', () async {
    final graphQlProvider = MockGraphQlProvider();
    when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

    AuthRepository authRepository = Get.put(AuthRepository(graphQlProvider));
    AuthService authService = Get.put(AuthService(authRepository, provider));

    when(graphQlProvider.recoverUserPassword(
            UserLogin('login'), null, null, null))
        .thenAnswer((realInvocation) => Future.value());

    when(graphQlProvider.validateUserPasswordRecoveryCode(
            UserLogin('login'), null, null, null, ConfirmationCode('1234')))
        .thenAnswer((realInvocation) => Future.value());

    when(graphQlProvider.resetUserPassword(UserLogin('login'), null, null, null,
            ConfirmationCode('1234'), UserPassword('123456')))
        .thenAnswer((realInvocation) => Future.value());

    await authService.recoverUserPassword(login: UserLogin('login'));
    await authService.validateUserPasswordRecoveryCode(
      login: UserLogin('login'),
      code: ConfirmationCode('1234'),
    );
    await authService.resetUserPassword(
      login: UserLogin('login'),
      code: ConfirmationCode('1234'),
      newPassword: UserPassword('123456'),
    );
    verifyInOrder([
      graphQlProvider.recoverUserPassword(UserLogin('login'), null, null, null),
      graphQlProvider.validateUserPasswordRecoveryCode(
          UserLogin('login'), null, null, null, ConfirmationCode('1234')),
      graphQlProvider.resetUserPassword(UserLogin('login'), null, null, null,
          ConfirmationCode('1234'), UserPassword('123456')),
    ]);
  });

  test('AuthService fails to reset a password', () async {
    final graphQlProvider = MockGraphQlProvider();
    when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

    AuthRepository authRepository = Get.put(AuthRepository(graphQlProvider));
    AuthService authService = Get.put(AuthService(authRepository, provider));

    when(graphQlProvider.recoverUserPassword(
            UserLogin('unknown'), null, null, null))
        .thenThrow(const RecoverUserPasswordException(
            RecoverUserPasswordErrorCode.unknownUser));

    when(graphQlProvider.recoverUserPassword(
            UserLogin('empty'), null, null, null))
        .thenThrow(const RecoverUserPasswordException(
            RecoverUserPasswordErrorCode.nowhereToSend));

    when(graphQlProvider.validateUserPasswordRecoveryCode(
            UserLogin('unknown'), null, null, null, ConfirmationCode('1111')))
        .thenThrow(const ValidateUserPasswordRecoveryCodeException(
            ValidateUserPasswordRecoveryErrorCode.wrongCode));

    when(graphQlProvider.resetUserPassword(UserLogin('unknown'), null, null,
            null, ConfirmationCode('1111'), UserPassword('123456')))
        .thenThrow(const ResetUserPasswordException(
            ResetUserPasswordErrorCode.wrongCode));

    expect(
        () async =>
            await authService.recoverUserPassword(login: UserLogin('unknown')),
        throwsA(isA<RecoverUserPasswordException>()));

    expect(
        () async =>
            await authService.recoverUserPassword(login: UserLogin('empty')),
        throwsA(isA<RecoverUserPasswordException>()));

    expect(
        () async => await authService.validateUserPasswordRecoveryCode(
              login: UserLogin('unknown'),
              code: ConfirmationCode('1111'),
            ),
        throwsA(isA<ValidateUserPasswordRecoveryCodeException>()));

    expect(
        () async => await authService.resetUserPassword(
              login: UserLogin('unknown'),
              code: ConfirmationCode('1111'),
              newPassword: UserPassword('123456'),
            ),
        throwsA(isA<ResetUserPasswordException>()));

    verifyInOrder([
      graphQlProvider.recoverUserPassword(
          UserLogin('unknown'), null, null, null),
      graphQlProvider.recoverUserPassword(UserLogin('empty'), null, null, null),
      graphQlProvider.validateUserPasswordRecoveryCode(
          UserLogin('unknown'), null, null, null, ConfirmationCode('1111')),
      graphQlProvider.resetUserPassword(UserLogin('unknown'), null, null, null,
          ConfirmationCode('1111'), UserPassword('123456'))
    ]);
  });

  test('AuthService identifies wrong confirmation code', () async {
    final graphQlProvider = MockGraphQlProvider();
    when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

    AuthRepository authRepository = Get.put(AuthRepository(graphQlProvider));
    AuthService authService = Get.put(AuthService(authRepository, provider));

    when(graphQlProvider.recoverUserPassword(
            UserLogin('login'), null, null, null))
        .thenAnswer((realInvocation) => Future.value());

    when(graphQlProvider.validateUserPasswordRecoveryCode(
            UserLogin('login'), null, null, null, ConfirmationCode('1111')))
        .thenThrow(const ValidateUserPasswordRecoveryCodeException(
            ValidateUserPasswordRecoveryErrorCode.wrongCode));

    when(graphQlProvider.resetUserPassword(UserLogin('login'), null, null, null,
            ConfirmationCode('1111'), UserPassword('123456')))
        .thenThrow(const ResetUserPasswordException(
            ResetUserPasswordErrorCode.wrongCode));

    await authService.recoverUserPassword(login: UserLogin('login'));

    expect(
        () async => await authService.validateUserPasswordRecoveryCode(
              login: UserLogin('login'),
              code: ConfirmationCode('1111'),
            ),
        throwsA(isA<ValidateUserPasswordRecoveryCodeException>()));

    expect(
        () async => await authService.resetUserPassword(
              login: UserLogin('login'),
              code: ConfirmationCode('1111'),
              newPassword: UserPassword('123456'),
            ),
        throwsA(isA<ResetUserPasswordException>()));
    verifyInOrder([
      graphQlProvider.recoverUserPassword(UserLogin('login'), null, null, null),
      graphQlProvider.validateUserPasswordRecoveryCode(
          UserLogin('login'), null, null, null, ConfirmationCode('1111')),
      graphQlProvider.resetUserPassword(UserLogin('login'), null, null, null,
          ConfirmationCode('1111'), UserPassword('123456'))
    ]);
  });
}

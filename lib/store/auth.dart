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

import 'package:get/get.dart';

import '/api/backend/extension/credentials.dart';
import '/api/backend/extension/my_user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/fcm_registration_token.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/repository/auth.dart';
import '/provider/gql/base.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/credentials.dart';
import '/provider/hive/my_user.dart';
import '/util/log.dart';

/// Implementation of an [AbstractAuthRepository].
///
/// All methods may throw [ConnectionException], [GraphQlException].
class AuthRepository implements AbstractAuthRepository {
  AuthRepository(
    this._graphQlProvider,
    this._myUserProvider,
    this._credentialsProvider,
  );

  @override
  final RxList<Session> sessions = RxList();

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [MyUserHiveProvider] for removing [MyUser]s.
  final MyUserHiveProvider _myUserProvider;

  /// [CredentialsHiveProvider] for removing [Credentials].
  final CredentialsHiveProvider _credentialsProvider;

  // TODO: Temporary solution, wait for support from backend.
  /// [Credentials] of [Session] created with [signUpWithEmail] returned in
  /// successful [confirmSignUpEmail].
  Credentials? _signUpCredentials;

  // TODO: Temporary solution, wait for support from backend.
  /// [HiveMyUser] created with [signUpWithEmail] and put to [Hive] in
  /// successful [confirmSignUpEmail].
  HiveMyUser? _signedUpUser;

  @override
  set token(AccessTokenSecret? token) {
    Log.debug('set token($token)', '$runtimeType');

    _graphQlProvider.token = token;
    if (token == null) {
      _graphQlProvider.disconnect();
    }
  }

  @override
  set authExceptionHandler(
    Future<void> Function(AuthorizationException) handler,
  ) {
    Log.debug('set authExceptionHandler(handler)', '$runtimeType');
    _graphQlProvider.authExceptionHandler = handler;
  }

  @override
  void applyToken() {
    Log.debug('applyToken()', '$runtimeType');
    _graphQlProvider.reconnect();
  }

  @override
  Future<Credentials> signUp() async {
    Log.debug('signUp()', '$runtimeType');

    final response = await _graphQlProvider.signUp();

    _myUserProvider.put(response.createUser.user.toHive());

    return response.toModel();
  }

  @override
  Future<Credentials> signIn(
    UserPassword password, {
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) async {
    Log.debug(
      'signIn(***, $login, $num, $email, $phone)',
      '$runtimeType',
    );

    final response =
        await _graphQlProvider.signIn(password, login, num, email, phone);

    _myUserProvider.put(response.user.toHive());

    return response.toModel();
  }

  @override
  Future<void> signUpWithEmail(UserEmail email) async {
    Log.debug('signUpWithEmail($email)', '$runtimeType');

    _signUpCredentials = null;

    final response = await _graphQlProvider.signUp();

    _signedUpUser = response.createUser.user.toHive();
    _signUpCredentials = response.toModel();

    await _graphQlProvider.addUserEmail(
      email,
      raw: RawClientOptions(_signUpCredentials!.access.secret),
    );
  }

  @override
  Future<Credentials> confirmSignUpEmail(
    ConfirmationCode code,
  ) async {
    Log.debug('confirmSignUpEmail($code)', '$runtimeType');

    if (_signUpCredentials == null) {
      throw ArgumentError.notNull('_signUpCredentials');
    } else if (_signedUpUser == null) {
      throw ArgumentError.notNull('_signedUpUser');
    }

    await _graphQlProvider.confirmEmailCode(
      code,
      raw: RawClientOptions(_signUpCredentials!.access.secret),
    );

    _myUserProvider.put(_signedUpUser!);

    return _signUpCredentials!;
  }

  @override
  Future<void> resendSignUpEmail() async {
    Log.debug('resendSignUpEmail()', '$runtimeType');

    if (_signUpCredentials == null) {
      throw ArgumentError.notNull('_signUpCredentials');
    }

    await _graphQlProvider.resendEmail(
      raw: RawClientOptions(_signUpCredentials!.access.secret),
    );
  }

  @override
  Future<void> deleteSession({
    SessionId? id,
    UserPassword? password,
    FcmRegistrationToken? fcmToken,
    AccessTokenSecret? accessToken,
  }) async {
    Log.debug(
      'deleteSession(id: $id, password: ${password?.obscured}, fcmToken: $fcmToken, accessToken: $accessToken)',
      '$runtimeType',
    );

    if (fcmToken != null) {
      await _graphQlProvider.unregisterFcmDevice(fcmToken);
    }

    await _graphQlProvider.deleteSession(
      id: id,
      password: password,
      token: accessToken,
    );

    if (id != null) {
      sessions.removeWhere((e) => e.id == id);
    }
  }

  @override
  Future<void> removeAccount(UserId id) async {
    Log.debug('removeAccount($id)', '$runtimeType');

    await _myUserProvider.remove(id);
    await _credentialsProvider.remove(id);
  }

  @override
  Future<void> validateToken(Credentials credentials) async {
    Log.debug('validateToken($credentials)', '$runtimeType');
    await _graphQlProvider.validateToken(credentials);
  }

  @override
  Future<Credentials> refreshSession(
    RefreshTokenSecret secret, {
    bool reconnect = true,
  }) {
    Log.debug('refreshSession($secret)', '$runtimeType');

    return _graphQlProvider.clientGuard.protect(() async {
      final response =
          (await _graphQlProvider.refreshSession(secret)).refreshSession
              as RefreshSession$Mutation$RefreshSession$CreateSessionOk;

      if (reconnect) {
        _graphQlProvider.token = response.accessToken.secret;
        _graphQlProvider.reconnect();
      }

      return response.toModel();
    });
  }

  @override
  Future<void> recoverUserPassword({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) async {
    Log.debug(
      'recoverUserPassword($login, $num, $email, $phone)',
      '$runtimeType',
    );

    await _graphQlProvider.recoverUserPassword(login, num, email, phone);
  }

  @override
  Future<void> validateUserPasswordRecoveryCode({
    required ConfirmationCode code,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) async {
    Log.debug(
      'validateUserPasswordRecoveryCode($code, $login, $num, $email, $phone)',
      '$runtimeType',
    );

    await _graphQlProvider.validateUserPasswordRecoveryCode(
      login,
      num,
      email,
      phone,
      code,
    );
  }

  @override
  Future<void> resetUserPassword({
    required ConfirmationCode code,
    required UserPassword newPassword,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) async {
    Log.debug(
      'resetUserPassword($code, ***, $login, $num, $email, $phone)',
      '$runtimeType',
    );

    await _graphQlProvider.resetUserPassword(
      login,
      num,
      email,
      phone,
      code,
      newPassword,
    );
  }

  @override
  Future<ChatId> useChatDirectLink(ChatDirectLinkSlug slug) async {
    Log.debug('useChatDirectLink($slug)', '$runtimeType');

    var response = await _graphQlProvider.useChatDirectLink(slug);
    return response.chat.id;
  }

  @override
  Future<void> updateSessions() async {
    Log.debug('updateSessions()', '$runtimeType');
    sessions.value =
        (await _graphQlProvider.sessions()).map((e) => e.toModel()).toList();
  }
}

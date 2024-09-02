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

import 'dart:async';

import 'package:collection/collection.dart';
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
import '/provider/drift/credentials.dart';
import '/provider/drift/my_user.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';

/// Implementation of an [AbstractAuthRepository].
///
/// All methods may throw [ConnectionException], [GraphQlException].
class AuthRepository extends DisposableInterface
    implements AbstractAuthRepository {
  AuthRepository(
    this._graphQlProvider,
    this._myUserProvider,
    this._credentialsProvider,
  );

  @override
  final RxList<MyUser> profiles = RxList();

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [MyUserDriftProvider] for removing [MyUser]s.
  final MyUserDriftProvider _myUserProvider;

  /// [CredentialsDriftProvider] for removing [Credentials].
  final CredentialsDriftProvider _credentialsProvider;

  /// [StreamSubscription] for the [MyUserDriftProvider.watch].
  StreamSubscription? _profilesSubscription;

  @override
  set token(AccessTokenSecret? token) {
    Log.debug('set token($token)', '$runtimeType');

    _graphQlProvider.token = token;
    if (token == null) {
      _graphQlProvider.disconnect();
    } else {
      _graphQlProvider.reconnect();
    }
  }

  @override
  set authExceptionHandler(
    Future<void> Function(AuthorizationException)? handler,
  ) {
    Log.debug('set authExceptionHandler(handler)', '$runtimeType');
    _graphQlProvider.authExceptionHandler = handler;
  }

  @override
  void onInit() {
    _profilesSubscription = _myUserProvider.watch().listen((ops) {
      for (var e in ops) {
        switch (e.op) {
          case OperationKind.added:
          case OperationKind.updated:
            profiles.addIf(
              profiles.none((m) => m.id.val == e.key?.val),
              e.value!.value,
            );
            break;

          case OperationKind.removed:
            profiles.removeWhere((m) => m.id.val == e.key?.val);
            break;
        }
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    _profilesSubscription?.cancel();
    super.onClose();
  }

  @override
  void applyToken() {
    Log.debug('applyToken()', '$runtimeType');
    _graphQlProvider.reconnect();
  }

  @override
  Future<Credentials> signUp({
    UserPassword? password,
    UserLogin? login,
  }) async {
    Log.debug(
      'signUp(password: ${password?.obscured}, login: $login)',
      '$runtimeType',
    );

    final response = await _graphQlProvider.signUp(
      login: login,
      password: password,
    );
    final success = response as SignUp$Mutation$CreateUser$CreateSessionOk;

    _myUserProvider.upsert(success.user.toDto());

    return success.toModel();
  }

  @override
  Future<Credentials> signIn({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    UserPassword? password,
    ConfirmationCode? code,
  }) async {
    Log.debug(
      'signIn(password: ${password?.obscured}, code: $code, login: $login, num: $num, email: ${email?.obscured}, phone: ${phone?.obscured})',
      '$runtimeType',
    );

    final response = await _graphQlProvider.signIn(
      credentials: MyUserCredentials(code: code, password: password),
      identifier: MyUserIdentifier(
        login: login,
        num: num,
        phone: phone,
        email: email,
      ),
    );

    _myUserProvider.upsert(response.user.toDto());

    return response.toModel();
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
      confirmation:
          password == null ? null : MyUserCredentials(password: password),
      token: accessToken,
    );
  }

  @override
  Future<void> removeAccount(UserId id, {bool keepProfile = false}) async {
    Log.debug('removeAccount($id)', '$runtimeType');

    if (!keepProfile) {
      profiles.removeWhere((e) => e.id == id);
    }

    await Future.wait([
      if (!keepProfile) _myUserProvider.delete(id),
      _credentialsProvider.delete(id),
    ]);
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
  Future<void> updateUserPassword({
    required ConfirmationCode code,
    required UserPassword newPassword,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) async {
    Log.debug(
      'updateUserPassword($code, ***, $login, $num, $email, $phone)',
      '$runtimeType',
    );

    await _graphQlProvider.updateUserPassword(
      identifier: MyUserIdentifier(
        login: login,
        num: num,
        email: email,
        phone: phone,
      ),
      confirmation: MyUserCredentials(code: code),
      newPassword: newPassword,
    );
  }

  @override
  Future<ChatId> useChatDirectLink(ChatDirectLinkSlug slug) async {
    Log.debug('useChatDirectLink($slug)', '$runtimeType');

    var response = await _graphQlProvider.useChatDirectLink(slug);
    return response.chat.id;
  }

  @override
  Future<void> createConfirmationCode({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    String? locale,
  }) async {
    Log.debug(
      'createConfirmationCode(login: $login, num: $num, email: ${email?.obscured}, phone: ${phone?.obscured}, locale: $locale)',
      '$runtimeType',
    );

    await _graphQlProvider.createConfirmationCode(
      MyUserIdentifier(
        login: login,
        num: num,
        email: email,
        phone: phone,
      ),
      locale: locale,
    );
  }

  @override
  Future<void> validateConfirmationCode({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    required ConfirmationCode code,
  }) async {
    Log.debug(
      'validateConfirmationCode(login: $login, num: $num, email: ${email?.obscured}, phone: ${phone?.obscured}, code: $code)',
      '$runtimeType',
    );

    await _graphQlProvider.validateConfirmationCode(
      identifier: MyUserIdentifier(
        login: login,
        num: num,
        email: email,
        phone: phone,
      ),
      code: code,
    );
  }
}

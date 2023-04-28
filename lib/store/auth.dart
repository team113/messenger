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

import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/fcm_registration_token.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/repository/auth.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';

/// Implementation of an [AbstractAuthRepository].
///
/// All methods may throw [ConnectionException], [GraphQlException].
class AuthRepository implements AbstractAuthRepository {
  AuthRepository(this._graphQlProvider);

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  @override
  set token(AccessToken? token) {
    _graphQlProvider.token = token;
    if (token == null) {
      _graphQlProvider.disconnect();
    }
  }

  @override
  set authExceptionHandler(
          Future<void> Function(AuthorizationException) handler) =>
      _graphQlProvider.authExceptionHandler = handler;

  @override
  void applyToken() => _graphQlProvider.reconnect();

  @override
  Future<bool> checkUserIdentifiable(UserLogin? login, UserNum? num,
          UserEmail? email, UserPhone? phone) async =>
      await _graphQlProvider.checkUserIdentifiable(login, num, email, phone);

  @override
  Future<Credentials> signUp() async {
    var response = await _graphQlProvider.signUp();
    return Credentials(
      Session(
        response.createUser.session.token,
        response.createUser.session.expireAt,
      ),
      RememberedSession(
        response.createUser.remembered!.token,
        response.createUser.remembered!.expireAt,
      ),
      response.createUser.user.id,
    );
  }

  @override
  Future<Credentials> signIn(UserPassword password,
      {UserLogin? login,
      UserNum? num,
      UserEmail? email,
      UserPhone? phone}) async {
    var response =
        await _graphQlProvider.signIn(password, login, num, email, phone, true);
    return Credentials(
      Session(
        response.session.token,
        response.session.expireAt,
      ),
      RememberedSession(
        response.remembered!.token,
        response.remembered!.expireAt,
      ),
      response.user.id,
    );
  }

  @override
  Future<void> logout([FcmRegistrationToken? fcmRegistrationToken]) async {
    if (fcmRegistrationToken != null) {
      await _graphQlProvider.unregisterFcmDevice(fcmRegistrationToken);
    }
    await _graphQlProvider.deleteSession();
  }

  @override
  Future<void> validateToken() async => await _graphQlProvider.validateToken();

  @override
  Future<Credentials> renewSession(RememberToken token) =>
      _graphQlProvider.clientGuard.protect(() async {
        var response = (await _graphQlProvider.renewSession(token)).renewSession
            as RenewSession$Mutation$RenewSession$RenewSessionOk;
        _graphQlProvider.token = response.session.token;
        _graphQlProvider.reconnect();
        return Credentials(
          Session(
            response.session.token,
            response.session.expireAt,
          ),
          RememberedSession(
            response.remembered.token,
            response.remembered.expireAt,
          ),
          response.user.id,
        );
      });

  @override
  Future<void> recoverUserPassword({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) =>
      _graphQlProvider.recoverUserPassword(login, num, email, phone);

  @override
  Future<void> validateUserPasswordRecoveryCode({
    required ConfirmationCode code,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) =>
      _graphQlProvider.validateUserPasswordRecoveryCode(
          login, num, email, phone, code);

  @override
  Future<void> resetUserPassword({
    required ConfirmationCode code,
    required UserPassword newPassword,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) =>
      _graphQlProvider.resetUserPassword(
          login, num, email, phone, code, newPassword);

  @override
  Future<ChatId> useChatDirectLink(ChatDirectLinkSlug slug) async {
    var response = await _graphQlProvider.useChatDirectLink(slug);
    return response.chat.id;
  }
}

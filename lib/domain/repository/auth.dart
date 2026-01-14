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

import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/push_token.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/provider/gql/exceptions.dart';

/// Authentication repository interface.
///
/// All methods may throw [ConnectionException] and [GraphQlException].
abstract class AbstractAuthRepository {
  // TODO: Remove, [AbstractMyUserRepository.profiles] should be used instead.
  /// Returns the known [MyUser] profiles.
  RxList<MyUser> get profiles;

  /// Sets an authorization `token` of this repository.
  set token(AccessTokenSecret? token);

  /// Sets [handler] that will be called on any [AuthorizationException].
  set authExceptionHandler(
    Future<void> Function(AuthorizationException)? handler,
  );

  /// Applies the specified [token] right away instead of the lazy reconnection.
  ///
  /// [token] is lazily applied to the remote, so in order to force the
  /// reconnection right away this method may be used.
  void applyToken();

  /// Creates a new [MyUser] having only [UserId] and [UserNum] fields, and
  /// creates a new [Session] for this [MyUser].
  ///
  /// Once the created [Session] expires, the created [MyUser] looses access, if
  /// he doesn't re-sign in within that period of time.
  Future<Credentials> signUp({UserPassword? password, UserLogin? login});

  /// Creates a new [Session] for the [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of four should be specified).
  Future<Credentials> signIn({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    UserPassword? password,
    ConfirmationCode? code,
  });

  /// Invalidates a [Session] with the provided [id] of the [MyUser] identified
  /// by the [accessToken], if any, or otherwise [Session] of the [MyUser]
  /// identified by the [token].
  ///
  /// Unregisters a device (Android, iOS, or Web) from receiving notifications
  /// via Firebase Cloud Messaging, if [token] is provided.
  Future<void> deleteSession({
    SessionId? id,
    UserPassword? password,
    ConfirmationCode? code,
    DeviceToken? token,
    AccessTokenSecret? accessToken,
  });

  /// Deletes the [MyUser] identified by the provided [id] from the accounts.
  ///
  /// If [keepProfile] is `true`, then keeps the [MyUser] in the [profiles].
  Future<void> removeAccount(UserId id, {bool keepProfile = false});

  /// Validates the [AccessToken] of the provided [Credentials].
  Future<void> validateToken(Credentials credentials);

  /// Refreshes the current [AccessToken].
  ///
  /// Invalidates the provided [RefreshToken] and returns a new one, which
  /// should be used instead.
  ///
  /// The renewed [Session] has its own expiration after renewal, so to renew it
  /// again use this method with the new returned [RefreshToken] (omit using
  /// old ones).
  ///
  /// If [reconnect] is `true`, then applies the retrieved [Credentials] as the
  /// [token] right away.
  Future<Credentials> refreshSession(
    RefreshTokenSecret secret, {
    RefreshSessionSecrets? input,
    bool reconnect,
  });

  /// Resets password for a [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of fourth should be specified)
  /// and recovery [ConfirmationCode].
  ///
  /// If [MyUser] has no password yet, then [newPassword] will be his first
  /// password unlocking the sign-in capability.
  Future<void> updateUserPassword({
    required ConfirmationCode code,
    required UserPassword newPassword,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  });

  /// Generates and sends a new single-use [ConfirmationCode] for the [MyUser]
  /// identified by the provided [login], [num], [email] and/or [phone].
  Future<void> createConfirmationCode({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    String? locale,
  });

  /// Validates the provided ConfirmationCode for the MyUser identified by the
  /// provided [login], [num], [email] and/or [phone] without using it.
  Future<void> validateConfirmationCode({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    required ConfirmationCode code,
  });
}

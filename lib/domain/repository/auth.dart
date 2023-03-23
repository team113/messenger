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

import '/domain/model/chat.dart';
import '/domain/model/fcm_registration_token.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/provider/gql/exceptions.dart';

/// Authentication repository interface.
///
/// All methods may throw [ConnectionException] and [GraphQlException].
abstract class AbstractAuthRepository {
  /// Sets an authorization `token` of this repository.
  set token(AccessToken? token);

  /// Sets [handler] that will be called on any [AuthorizationException].
  set authExceptionHandler(
      Future<void> Function(AuthorizationException) handler);

  /// Applies the specified [token] right away instead of the lazy reconnection.
  ///
  /// [token] is lazily applied to the remote, so in order to force the
  /// reconnection right away this method may be used.
  void applyToken();

  /// Indicates whether some [User] can be identified by the given [num],
  /// [login], [email] or [phone].
  ///
  /// Exactly one of [num]/[login]/[email]/[phone] arguments must be specified.
  Future<bool> checkUserIdentifiable(
      UserLogin? login, UserNum? num, UserEmail? email, UserPhone? phone);

  /// Creates a new [MyUser] having only [UserId] and [UserNum] fields, and
  /// creates a new [Session] for this [MyUser].
  ///
  /// Once the created [Session] expires, the created [MyUser] looses access, if
  /// he doesn't re-sign in within that period of time.
  Future<Credentials> signUp();

  /// Creates a new [Session] for the [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of four should be specified).
  Future<Credentials> signIn(UserPassword password,
      {UserLogin? login, UserNum? num, UserEmail? email, UserPhone? phone});

  /// Deletes a [Session] of the [MyUser] identified by the [token] of this
  /// repository.
  ///
  /// Unregisters a device (Android, iOS, or Web) from receiving notifications
  /// via Firebase Cloud Messaging, if [fcmRegistrationToken] is provided.
  Future<void> logout({FcmRegistrationToken? fcmRegistrationToken});

  /// Validates the current [AccessToken].
  Future<void> validateToken();

  /// Refreshes the current [AccessToken].
  ///
  /// Invalidates the provided [RememberToken] and returns a new one, which
  /// should be used instead.
  ///
  /// The renewed [Session] has its own expiration after renewal, so to renew it
  /// again use this method with the new returned [RememberToken] (omit using
  /// old ones).
  Future<Credentials> renewSession(RememberToken token);

  /// Initiates password recovery for a [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of fourth should be specified).
  ///
  /// Sends a recovery [ConfirmationCode] to [MyUser]'s `email` and `phone`.
  ///
  /// If [MyUser] has no password yet, then this method still may be used for
  /// recovering his sign-in capability.
  ///
  /// The number of generated [ConfirmationCode]s is limited up to 10 per 1
  /// hour.
  Future<void> recoverUserPassword(
      {UserLogin? login, UserNum? num, UserEmail? email, UserPhone? phone});

  /// Validates the provided password recovery [ConfirmationCode] for a [MyUser]
  /// identified by the provided [num]/[login]/[email]/[phone] (exactly one of
  /// fourth should be specified).
  Future<void> validateUserPasswordRecoveryCode({
    required ConfirmationCode code,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  });

  /// Resets password for a [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of fourth should be specified)
  /// and recovery [ConfirmationCode].
  ///
  /// If [MyUser] has no password yet, then [newPassword] will be his first
  /// password unlocking the sign-in capability.
  Future<void> resetUserPassword({
    required ConfirmationCode code,
    required UserPassword newPassword,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  });

  /// Uses the specified [ChatDirectLink] by the authenticated [MyUser] creating
  /// a new [Chat]-dialog or joining an existing [Chat]-group.
  Future<ChatId> useChatDirectLink(ChatDirectLinkSlug slug);
}

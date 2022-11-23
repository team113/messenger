// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:graphql_flutter/graphql_flutter.dart';

import '../base.dart';
import '../exceptions.dart';
import '/api/backend/schema.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';

/// Authentication related functionality.
abstract class AuthGraphQlMixin {
  GraphQlClient get client;
  AccessToken? get token;
  set token(AccessToken? value);

  /// Indicates whether some [User] can be identified by the given [num],
  /// [login], [email] or [phone].
  ///
  /// Exactly one of [num]/[login]/[email]/[phone] arguments must be specified.
  ///
  /// ### Authentication
  ///
  /// None.
  Future<bool> checkUserIdentifiable(UserLogin? login, UserNum? num,
      UserEmail? email, UserPhone? phone) async {
    final variables = CheckUserIdentifiableArguments(
      num: num,
      login: login,
      email: email,
      phone: phone,
    );
    final QueryResult result = await client.query(QueryOptions(
      operationName: 'CheckUserIdentifiable',
      document: CheckUserIdentifiableQuery(variables: variables).document,
      variables: variables.toJson(),
    ));
    return CheckUserIdentifiable$Query.fromJson(result.data!)
        .checkUserIdentifiable;
  }

  /// Creates a new [MyUser] having only `id` and unique `num` fields, along
  /// with a [Session] for him (valid for the returned expiration).
  ///
  /// The created [Session] may be prolonged via [renewSession] if the
  /// `remember` argument is specified (so the [RememberedSession] is returned
  /// as well).
  ///
  /// Once the created [Session] expires and cannot be prolonged, the created
  /// [MyUser] looses its access, if he doesn't provide a password via
  /// `Mutation.updateUserPassword` within that period of time.
  ///
  /// ### Authentication
  ///
  /// None.
  ///
  /// ### Non-idempotent
  ///
  /// Each time creates a new unique [MyUser] and a new [Session].
  Future<SignUp$Mutation> signUp([bool remember = true]) async {
    final variables = SignUpArguments(remember: remember);
    final QueryResult result = await client.query(QueryOptions(
      document: SignUpMutation(variables: variables).document,
      variables: variables.toJson(),
    ));
    return SignUp$Mutation.fromJson(result.data!);
  }

  /// Deletes an authorized [Session] by the stored [token].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Always returns `true` on success.
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op if the [Session] with the provided [AccessToken] has
  /// been deleted already.
  Future<void> deleteSession() async {
    if (token != null) {
      final variables = DeleteSessionArguments(token: token!);
      final QueryResult result = await client.query(QueryOptions(
        document: DeleteSessionMutation(variables: variables).document,
        variables: variables.toJson(),
      ));
      GraphQlProviderExceptions.fire(result);
    }
  }

  /// Creates a new [Session] for the [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of four should be specified).
  ///
  /// Represents a sign-in action.
  ///
  /// The created [Session] has expiration, which may be prolonged via
  /// [renewSession] if the [remember] argument is specified (so a
  /// [RememberedSession] is returned).
  ///
  /// ### Authentication
  ///
  /// None.
  ///
  /// ### Non-idempotent
  ///
  /// Each time creates a new [Session].
  Future<SignIn$Mutation$CreateSession$CreateSessionOk> signIn(
      UserPassword password,
      UserLogin? login,
      UserNum? num,
      UserEmail? email,
      UserPhone? phone,
      bool remember) async {
    final variables = SignInArguments(
      password: password,
      login: login,
      num: num,
      email: email,
      phone: phone,
      remember: remember,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        document: SignInMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => CreateSessionException(
          (SignIn$Mutation.fromJson(data).createSession
                  as SignIn$Mutation$CreateSession$CreateSessionError)
              .code),
      raw: true,
    );
    return SignIn$Mutation.fromJson(result.data!).createSession
        as SignIn$Mutation$CreateSession$CreateSessionOk;
  }

  /// Validates the current authorization token.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  Future<ValidateToken$Query> validateToken() async {
    QueryResult res = await client
        .query(QueryOptions(document: ValidateTokenQuery().document));
    return ValidateToken$Query.fromJson(res.data!);
  }

  /// Renews a [Session] of the authenticated [MyUser] identified by the
  /// provided [RememberToken].
  ///
  /// Invalidates the provided [RememberToken] and returns a new one, which
  /// should be used instead.
  ///
  /// The renewed [Session] has its own expiration after renewal, so to renew it
  /// again use this mutation with the new returned [RememberToken] (omit using
  /// old ones).
  ///
  /// The expiration of the renewed [RememberedSession] is not prolonged
  /// comparing to the previous one, and remains the same for all the
  /// [RememberedSession]s obtained via [renewSession]. Use [signIn] to reset
  /// expiration of a [RememberedSession].
  ///
  /// ### Authentication
  ///
  /// None.
  ///
  /// ### Non-idempotent
  ///
  /// Each time creates a new [Session] and generates a new [RememberToken].
  Future<RenewSession$Mutation> renewSession(RememberToken token) async {
    final variables = RenewSessionArguments(token: token);
    final QueryResult result = await client.mutate(
      MutationOptions(
        document: RenewSessionMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => RenewSessionException(
          (RenewSession$Mutation.fromJson(data).renewSession
                  as RenewSession$Mutation$RenewSession$RenewSessionError)
              .code),
      raw: true,
    );
    return RenewSession$Mutation.fromJson(result.data!);
  }

  /// Initiates password recovery for a [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of fourth should be specified).
  ///
  /// Sends a recovery [ConfirmationCode] to [MyUser]'s `email` and `phone`.
  ///
  /// If [MyUser] has no password yet, then this mutation still may be used for
  /// recovering his sign-in capability.
  ///
  /// The number of generated [ConfirmationCode]s is limited up to 10 per 1
  /// hour.
  ///
  /// ### Authentication
  ///
  /// None.
  ///
  /// ### Result
  ///
  /// Always returns `null` on success.
  ///
  /// ### Non-idempotent
  ///
  /// Each time sends a new unique password recovery [ConfirmationCode].
  Future<void> recoverUserPassword(UserLogin? login, UserNum? num,
      UserEmail? email, UserPhone? phone) async {
    if ([login, num, email, phone].where((e) => e != null).length != 1) {
      throw ArgumentError(
          'Exactly one of num/login/email/phone should be specified.');
    }

    final variables = RecoverUserPasswordArguments(
      num: num,
      login: login,
      email: email,
      phone: phone,
    );
    await client.query(
      QueryOptions(
        operationName: 'RecoverUserPassword',
        document: RecoverUserPasswordMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      (data) => RecoverUserPasswordException(
          RecoverUserPassword$Mutation.fromJson(data).recoverUserPassword
              as RecoverUserPasswordErrorCode),
    );
  }

  /// Validates the provided password recovery [ConfirmationCode] for a [MyUser]
  /// identified by the provided [num]/[login]/[email]/[phone] (exactly one of
  /// fourth should be specified).
  ///
  /// ### Authentication
  ///
  /// None.
  ///
  /// ### Result
  ///
  /// Always returns `null` on success.
  ///
  /// ### Idempotent
  ///
  /// [ConfirmationCode] can be validated unlimited number of times (for now).
  Future<void> validateUserPasswordRecoveryCode(UserLogin? login, UserNum? num,
      UserEmail? email, UserPhone? phone, ConfirmationCode code) async {
    if ([login, num, email, phone].where((e) => e != null).length != 1) {
      throw ArgumentError(
          'Exactly one of num/login/email/phone should be specified.');
    }

    final variables = ValidateUserPasswordRecoveryCodeArguments(
      num: num,
      login: login,
      email: email,
      phone: phone,
      code: code,
    );
    await client.query(
      QueryOptions(
        operationName: 'ValidateUserPasswordRecoveryCode',
        document: ValidateUserPasswordRecoveryCodeMutation(variables: variables)
            .document,
        variables: variables.toJson(),
      ),
      (data) => ValidateUserPasswordRecoveryCodeException(
          ValidateUserPasswordRecoveryCode$Mutation.fromJson(data)
                  .validateUserPasswordRecoveryCode
              as ValidateUserPasswordRecoveryErrorCode),
    );
  }

  /// Resets password for a [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of fourth should be specified),
  /// and authenticating the mutation with the provided recovery
  /// [ConfirmationCode].
  ///
  /// If [MyUser] has no password yet, then [newPassword] will be his first
  /// password unlocking the sign-in capability.
  ///
  /// ### Authentication
  ///
  /// None.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] is always produced on success:
  /// - [EventUserPasswordUpdated].
  ///
  /// ### Non-idempotent
  ///
  /// Errors with `WRONG_CODE` if the provided [ConfirmationCode] was used
  /// already.
  Future<MyUserEventsVersionedMixin?> resetUserPassword(
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    ConfirmationCode code,
    UserPassword newPassword,
  ) async {
    if ([login, num, email, phone].where((e) => e != null).length != 1) {
      throw ArgumentError(
          'Exactly one of num/login/email/phone should be specified.');
    }

    final variables = ResetUserPasswordArguments(
      num: num,
      login: login,
      email: email,
      phone: phone,
      code: code,
      newPassword: newPassword,
    );
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'ResetUserPassword',
        document: ResetUserPasswordMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      (data) => ResetUserPasswordException((ResetUserPassword$Mutation.fromJson(
                      data)
                  .resetUserPassword
              as ResetUserPassword$Mutation$ResetUserPassword$ResetUserPasswordError)
          .code),
    );
    return ResetUserPassword$Mutation.fromJson(result.data!).resetUserPassword
        as MyUserEventsVersionedMixin?;
  }
}

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

import 'package:graphql_flutter/graphql_flutter.dart';

import '../base.dart';
import '../exceptions.dart';
import '/api/backend/schema.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/util/log.dart';

/// Authentication related functionality.
mixin AuthGraphQlMixin {
  GraphQlClient get client;

  AccessTokenSecret? get token;

  set token(AccessTokenSecret? value);

  /// Creates a new [MyUser] having only `id` and unique `num` fields, along
  /// with a [Session] for him (valid for the returned expiration).
  ///
  /// The created [Session] should be prolonged via [refreshSession].
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
  Future<SignUp$Mutation> signUp() async {
    Log.debug('signUp()', '$runtimeType');

    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'SignUp',
        document: SignUpMutation().document,
      ),
      raw: const RawClientOptions(),
    );
    return SignUp$Mutation.fromJson(result.data!);
  }

  /// Destroys the specified [Session] of the authenticated [MyUser], or the
  /// current one (if its [id] is not specified).
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Always returns `null` on success.
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op if the specified [Session] has been deleted already.
  Future<void> deleteSession({
    SessionId? id,
    UserPassword? password,
    AccessTokenSecret? token,
  }) async {
    token ??= this.token;

    Log.debug(
      'deleteSession(id: $id, password: ${password?.obfuscated}, token: $token)',
      '$runtimeType',
    );

    if (token != null) {
      final variables = DeleteSessionArguments(id: id, password: password);
      final QueryResult result = await client.mutate(
        MutationOptions(
          operationName: 'DeleteSession',
          document: DeleteSessionMutation(variables: variables).document,
          variables: variables.toJson(),
        ),
        raw: RawClientOptions(token),
      );
      GraphQlProviderExceptions.fire(result);
    }
  }

  /// Creates a new [Session] for the [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of four should be specified).
  ///
  /// Represents a sign-in action.
  ///
  /// The created [Session] has expiration, which may be prolonged via
  /// [refreshSession].
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
  ) async {
    Log.debug('signIn(***, $login, $num, $email, $phone)', '$runtimeType');

    final variables = SignInArguments(
      password: password,
      login: login,
      num: num,
      email: email,
      phone: phone,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'SignIn',
        document: SignInMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => CreateSessionException(
          (SignIn$Mutation.fromJson(data).createSession
                  as SignIn$Mutation$CreateSession$CreateSessionError)
              .code),
      raw: const RawClientOptions(),
    );
    return SignIn$Mutation.fromJson(result.data!).createSession
        as SignIn$Mutation$CreateSession$CreateSessionOk;
  }

  /// Validates the authorization token of the provided [Credentials].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  Future<ValidateToken$Query> validateToken(Credentials creds) async {
    Log.debug('validateToken($creds)', '$runtimeType');

    final QueryResult res = await client.mutate(
      MutationOptions(
        operationName: 'ValidateToken',
        document: ValidateTokenQuery().document,
      ),
      raw: RawClientOptions(creds.access.secret),
    );
    return ValidateToken$Query.fromJson(res.data!);
  }

  /// Refreshes a [Session] of the [MyUser] identified by the provided
  /// [RefreshTokenSecret].
  ///
  /// Invalidates the provided [RefreshTokenSecret] and returns a new one for
  /// the same [RefreshToken], which should be used instead.
  ///
  /// The refreshed [AccessToken] has its own expiration, so to refresh it
  /// again, use this mutation with the new returned [RefreshTokenSecret] (omit
  /// using old ones).
  ///
  /// [RefreshToken] doesn't change at all, only the new [RefreshTokenSecret] is
  /// generated for it, which means its expiration is not prolonged comparing to
  /// the [AccessToken]. Once the [RefreshToken] is expired, the [Session]
  /// cannot be either refreshed or accessed anymore. To create a new [Session]
  /// use the [signIn].
  ///
  /// `User-Agent` HTTP header must be specified for this action and meet the
  /// [UserAgent] scalar format.
  ///
  /// ### Authentication
  ///
  /// None.
  ///
  /// ### Non-idempotent
  ///
  /// Each time creates a new [AccessToken] and generates a new
  /// [RefreshTokenSecret] for the [RefreshToken].
  Future<RefreshSession$Mutation> refreshSession(
    RefreshTokenSecret secret,
  ) async {
    Log.debug('refreshSession($secret)', '$runtimeType');

    final variables = RefreshSessionArguments(secret: secret);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'RefreshSession',
        document: RefreshSessionMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => RefreshSessionException(
        (RefreshSession$Mutation.fromJson(data).refreshSession
                as RefreshSession$Mutation$RefreshSession$RefreshSessionError)
            .code,
      ),
      raw: const RawClientOptions(),
    );
    return RefreshSession$Mutation.fromJson(result.data!);
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
  Future<void> recoverUserPassword(
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  ) async {
    Log.debug(
      'recoverUserPassword($login, $num, $email, $phone)',
      '$runtimeType',
    );

    if ([login, num, email, phone].where((e) => e != null).length != 1) {
      throw ArgumentError(
        'Exactly one of num/login/email/phone should be specified.',
      );
    }

    final variables = RecoverUserPasswordArguments(
      num: num,
      login: login,
      email: email,
      phone: phone,
    );
    await client.mutate(
      MutationOptions(
        operationName: 'RecoverUserPassword',
        document: RecoverUserPasswordMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      raw: const RawClientOptions(),
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
  Future<void> validateUserPasswordRecoveryCode(
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    ConfirmationCode code,
  ) async {
    Log.debug(
      'validateUserPasswordRecoveryCode($login, $num, $email, $phone, $code)',
      '$runtimeType',
    );

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
    await client.mutate(
      MutationOptions(
        operationName: 'ValidateUserPasswordRecoveryCode',
        document: ValidateUserPasswordRecoveryCodeMutation(variables: variables)
            .document,
        variables: variables.toJson(),
      ),
      onException: (data) => ValidateUserPasswordRecoveryCodeException(
        ValidateUserPasswordRecoveryCode$Mutation.fromJson(data)
                .validateUserPasswordRecoveryCode
            as ValidateUserPasswordRecoveryErrorCode,
      ),
      raw: const RawClientOptions(),
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
  Future<void> resetUserPassword(
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    ConfirmationCode code,
    UserPassword newPassword,
  ) async {
    Log.debug(
      'validateUserPasswordRecoveryCode($login, $num, $email, $phone, $code, newPassword)',
      '$runtimeType',
    );

    if ([login, num, email, phone].where((e) => e != null).length != 1) {
      throw ArgumentError(
        'Exactly one of num/login/email/phone should be specified.',
      );
    }

    final variables = ResetUserPasswordArguments(
      num: num,
      login: login,
      email: email,
      phone: phone,
      code: code,
      newPassword: newPassword,
    );
    await client.mutate(
      MutationOptions(
        operationName: 'ResetUserPassword',
        document: ResetUserPasswordMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ResetUserPasswordException(
        (ResetUserPassword$Mutation.fromJson(data).resetUserPassword
                as ResetUserPassword$Mutation$ResetUserPassword$ResetUserPasswordError)
            .code,
      ),
      raw: const RawClientOptions(),
    );
  }
}

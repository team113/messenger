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

import 'dart:convert';

import 'package:dio/dio.dart' as dio show Options, FormData;
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
  Future<SignUp$Mutation$CreateUser> signUp({
    UserLogin? login,
    UserPassword? password,
  }) async {
    Log.debug('signUp()', '$runtimeType');

    final variables = SignUpArguments(login: login, password: password);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'SignUp',
        document: SignUpMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => SignUpException(
        SignUp$Mutation.fromJson(data).createUser as CreateSessionErrorCode,
      ),
      raw: const RawClientOptions(),
    );
    return SignUp$Mutation.fromJson(result.data!).createUser;
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
    MyUserCredentials? confirmation,
    AccessTokenSecret? token,
  }) async {
    token ??= this.token;

    Log.debug(
      'deleteSession(id: $id, confirmation: ***, token: $token)',
      '$runtimeType',
    );

    if (token != null) {
      final variables =
          DeleteSessionArguments(id: id, confirmation: confirmation);
      final QueryResult result = await client.mutate(
        MutationOptions(
          operationName: 'DeleteSession',
          document: DeleteSessionMutation(variables: variables).document,
          variables: variables.toJson(),
        ),
        onException: (data) => DeleteSessionException(
          DeleteSession$Mutation.fromJson(data).deleteSession
              as DeleteSessionErrorCode,
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
      credentials: MyUserCredentials(password: password),
      ident: MyUserIdentifier(
        login: login,
        num: num,
        email: email,
        phone: phone,
      ),
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

  /// Generates and sends a new single-use [ConfirmationCode] for the [MyUser]
  /// identified by the provided [MyUserIdentifier].
  ///
  /// If the concrete [MyUserIdentifier.email] address or
  /// [MyUserIdentifier.phone] number is provided, then sends the generated
  /// [ConfirmationCode] only there. Otherwise, if a [MyUserIdentifier.num] or a
  /// [MyUserIdentifier.login] is provided, then sends the generated
  /// [ConfirmationCode]s to all the possessed [MyUserEmails.confirmed] and
  /// [MyUserPhones.confirmed].
  ///
  /// If the [MyUser] has no password yet, then this mutation still may be used
  /// for recovering his sign-in capability.
  ///
  /// `User-Agent` HTTP header must be specified for this mutation and meet the
  /// [UserAgent] scalar format.
  ///
  /// ### Localization
  ///
  /// You may provide the preferred locale via the `Accept-Language` HTTP
  /// header, which will localize the sent email messages (or SMS) with the
  /// generated [ConfirmationCode] using the best match of the supported
  /// locales.
  ///
  /// ### Authentication
  ///
  /// None.
  ///
  /// ### Result
  ///
  /// Always returns `true` on success.
  ///
  /// ### Non-idempotent
  ///
  /// Each time generates and sends a new unique [ConfirmationCode].
  Future<void> createConfirmationCode(
    MyUserIdentifier identifier, {
    String? locale,
  }) async {
    Log.debug('createConfirmationCode($identifier)', '$runtimeType');

    final variables = CreateConfirmationCodeArguments(ident: identifier);
    final query = MutationOptions(
      operationName: 'CreateConfirmationCode',
      document: CreateConfirmationCodeMutation(variables: variables).document,
      variables: variables.toJson(),
    );

    final request = query.asRequest;
    final body = const RequestSerializer().serializeRequest(request);
    final encodedBody = json.encode(body);

    await client.post(
      dio.FormData.fromMap({
        'operations': encodedBody,
        'map': '{ "token": ["variables.token"] }',
        'token': const RawClientOptions().token ?? token,
      }),
      options: dio.Options(
        headers: {if (locale != null) 'Accept-Language': locale},
      ),
      operationName: query.operationName,
    );
  }

  /// Validates the provided [ConfirmationCode] for the MyUser identified by the provided [MyUserIdentifier] without using it.
  ///
  /// If the concrete [MyUserIdentifier.email] address or
  /// [MyUserIdentifier.phone] number is provided, then the provided
  /// [ConfirmationCode] is validated against it exclusively, meaning that
  /// providing [ConfirmationCode]s sent to any other [MyUserEmails.confirmed]
  /// or [MyUserPhones.confirmed] is invalid. Otherwise, if a
  /// [MyUserIdentifier.num] or a [MyUserIdentifier.login] is provided, then a
  /// [ConfirmationCode] sent to any of [MyUserEmails.confirmed] or
  /// [MyUserPhones.confirmed] is suitable.
  ///
  /// `User-Agent` HTTP header must be specified for this mutation and meet the
  /// [UserAgent] scalar format.
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
  Future<RefreshSession$Mutation> validateConfirmationCode({
    required MyUserIdentifier identifier,
    required ConfirmationCode code,
  }) async {
    Log.debug(
      'validateConfirmationCode(identifier: $identifier, code: $code)',
      '$runtimeType',
    );

    final variables =
        ValidateConfirmationCodeArguments(ident: identifier, code: code);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'ValidateConfirmationCode',
        document:
            ValidateConfirmationCodeMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ValidateConfirmationCodeException(
        (ValidateConfirmationCode$Mutation.fromJson(data)
            .validateConfirmationCode)!,
      ),
    );
    return RefreshSession$Mutation.fromJson(result.data!);
  }
}

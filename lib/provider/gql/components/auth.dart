// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import 'package:graphql/client.dart';

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
  /// [AccessToken] of the created [Session] may be prolonged via
  /// [refreshSession].
  ///
  /// Once the created [Session] expires and cannot be refreshed, the created
  /// [MyUser] looses its access, if he doesn't provide the [password] argument
  /// now or sets it later via `Mutation.updateUserPassword` within that period
  /// of time.
  ///
  /// `User-Agent` HTTP header must be specified for this mutation and meet the
  /// [UserAgent] scalar format.
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
        (SignUp$Mutation.fromJson(data).createUser
                as SignUp$Mutation$CreateUser$CreateUserError)
            .code,
      ),
      raw: const RawClientOptions(),
    );
    return SignUp$Mutation.fromJson(result.data!).createUser;
  }

  /// Destroys the specified [Session] of the authenticated [MyUser], or the
  /// current one (if the [id] argument is not provided).
  ///
  /// If the [id] argument is provided, then the confirmation argument is
  /// mandatory, unless the authenticated [MyUser] has no means for it (has
  /// neither [MyUser.hasPassword], nor
  /// [MyUserEmails.confirmed]/[MyUserPhones.confirmed]).
  ///
  /// `User-Agent` HTTP header must be specified for this mutation and meet the
  /// [UserAgent] scalar format.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [SessionEvent] may be produced on success:
  /// - [EventSessionDeleted].
  ///
  /// Idempotent
  ///
  /// Succeeds as no-op (and returns no `SessionEvent`) if the specified
  /// [Session] has been deleted already.
  ///
  /// However, always uses the provided [ConfirmationCode], disallowing to use
  /// it again.
  Future<void> deleteSession({
    SessionId? id,
    MyUserCredentials? confirmation,
    AccessTokenSecret? token,
  }) async {
    token ??= this.token;

    Log.debug(
      'deleteSession(id: $id, confirmation: ${confirmation?.obscured}, token: $token)',
      '$runtimeType',
    );

    if (token != null) {
      final variables = DeleteSessionArguments(
        id: id,
        confirmation: confirmation,
      );
      final QueryResult result = await client.mutate(
        MutationOptions(
          operationName: 'DeleteSession',
          document: DeleteSessionMutation(variables: variables).document,
          variables: variables.toJson(),
        ),
        onException: (data) => DeleteSessionException(
          (DeleteSession$Mutation.fromJson(data).deleteSession
                  as DeleteSession$Mutation$DeleteSession$DeleteSessionError)
              .code,
        ),
        raw: RawClientOptions(token),
      );
      GraphQlProviderExceptions.fire(result);
    }
  }

  /// Creates a new [Session] for the [MyUser] identified by the provided
  /// [MyUserIdentifier].
  ///
  /// Represents a sign-in action.
  ///
  /// [AccessToken] of the created [Session] may be prolonged via
  /// [refreshSession].
  ///
  /// If the provided [MyUserIdentifier.email] address (or
  /// [MyUserIdentifier.phone] number) is not occupied by any existing [MyUser]
  /// yet, then, along with provided [MyUserCredentials.code], creates a new
  /// [MyUser] with the authenticated [UserEmail] address (or [UserPhone]
  /// number) being assigned to him. This means, that there is no difference
  /// between sign-in and sign-up actions in this mutation when a [UserEmail]
  /// address (or [UserPhone] number) is used in combination with a
  /// [ConfirmationCode].
  ///
  /// `User-Agent` HTTP header must be specified for this mutation and meet the
  /// [UserAgent] scalar format.
  ///
  /// ### Authentication
  ///
  /// None.
  ///
  /// ### Non-idempotent
  ///
  /// Each time creates a new [Session].
  ///
  /// Additionally, always uses the provided [ConfirmationCode], disallowing to
  /// use it again.
  Future<SignIn$Mutation$CreateSession$CreateSessionOk> signIn({
    required MyUserCredentials credentials,
    required MyUserIdentifier identifier,
  }) async {
    Log.debug(
      'signIn(identifier: ${identifier.obscured}, credentials: ${credentials.obscured})',
      '$runtimeType',
    );

    final variables = SignInArguments(
      credentials: credentials,
      ident: identifier,
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
            .code,
      ),
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
    RefreshTokenSecret secret, {
    RefreshSessionSecretsInput? input,
  }) async {
    Log.debug(
      'refreshSession(${secret.obscured}, input: ${input?.obscured})',
      '$runtimeType',
    );

    final variables = RefreshSessionArguments(secret: secret, kw$new: input);
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
  Future<void> validateConfirmationCode({
    required MyUserIdentifier identifier,
    required ConfirmationCode code,
  }) async {
    Log.debug(
      'validateConfirmationCode(identifier: ${identifier.obscured}, code: $code)',
      '$runtimeType',
    );

    final variables = ValidateConfirmationCodeArguments(
      ident: identifier,
      code: code,
    );
    await client.mutate(
      MutationOptions(
        operationName: 'ValidateConfirmationCode',
        document: ValidateConfirmationCodeMutation(
          variables: variables,
        ).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ValidateConfirmationCodeException(
        (ValidateConfirmationCode$Mutation.fromJson(
          data,
        ).validateConfirmationCode)!,
      ),
    );
  }
}

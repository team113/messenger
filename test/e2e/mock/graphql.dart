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

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql/client.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/base.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/util/log.dart';
import 'package:mutex/mutex.dart';

/// Mocked [GraphQlProvider] containing the [MockGraphQlClient].
class MockGraphQlProvider extends GraphQlProvider {
  /// Mocked [GraphQlClient] itself.
  final MockGraphQlClient _client = MockGraphQlClient();

  @override
  MockGraphQlClient get client => _client;

  @override
  Mutex get clientGuard => _client.guard;

  @override
  AccessTokenSecret? get token => _client.token;

  @override
  set authExceptionHandler(Future<void> Function(AuthorizationException)? fn) =>
      _client.authExceptionHandler = fn;

  @override
  set token(AccessTokenSecret? value) => _client.token = value;

  @override
  RxBool get connected => _client.connected;

  @override
  Future<void> reconnect() => _client.reconnect();

  @override
  void disconnect() => _client.disconnect();

  @override
  void clearCache() => _client.clearCache();

  @override
  void addListener(void Function(Exception?) handler) =>
      _client.addListener(handler);

  @override
  void removeListener(void Function(Exception?) handler) =>
      _client.removeListener(handler);

  @override
  Future<MyUserEventsVersionedMixin?> addUserEmail(
    UserEmail email, {
    ConfirmationCode? confirmation,
    RawClientOptions? raw,
    String? locale,
  }) async {
    if (confirmation != null) {
      return AddUserEmail$Mutation.fromJson({
            'addUserEmail': {
              '__typename': 'MyUserEventsVersioned',
              'events': [
                {
                  '__typename': 'EventUserEmailAdded',
                  'userId': 'id',
                  'email': '$email',
                  'confirmed': true,
                  'at': DateTime.now().toString(),
                },
              ],
              'ver': '9' * 58,
            },
          }).addUserEmail
          as AddUserEmail$Mutation$AddUserEmail$MyUserEventsVersioned;
    }

    final variables = AddUserEmailArguments(
      email: email,
      confirmation: confirmation,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'AddUserEmail',
        document: AddUserEmailMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => AddUserEmailException(
        (AddUserEmail$Mutation.fromJson(data).addUserEmail
                as AddUserEmail$Mutation$AddUserEmail$AddUserEmailError)
            .code,
      ),
    );
    return AddUserEmail$Mutation.fromJson(result.data!).addUserEmail
        as AddUserEmail$Mutation$AddUserEmail$MyUserEventsVersioned;
  }

  @override
  Future<MyUserEventsVersionedMixin?> removeUserEmail(
    UserEmail phone, {
    MyUserCredentials? confirmation,
  }) async {
    return null;
  }

  @override
  Future<MyUserEventsVersionedMixin?> removeUserPhone(
    UserPhone phone, {
    MyUserCredentials? confirmation,
  }) async {
    return null;
  }

  @override
  Future<void> validateConfirmationCode({
    required MyUserIdentifier identifier,
    required ConfirmationCode code,
  }) {
    if (code.val == '1234') {
      return Future.value();
    }

    throw ValidateConfirmationCodeException(
      ValidateConfirmationCodeErrorCode.wrongCode,
    );
  }

  @override
  Future<MyUserEventsVersionedMixin?> updateUserPassword({
    MyUserIdentifier? identifier,
    UserPassword? newPassword,
    MyUserCredentials? confirmation,
  }) {
    if (identifier?.login?.val == 'alice' &&
        confirmation?.code?.val == '1234') {
      return Future.value(null);
    }

    return super.updateUserPassword(
      identifier: identifier,
      newPassword: newPassword,
      confirmation: confirmation,
    );
  }
}

/// Mocked [GraphQlClient] with an ability to add [delay] to its requests.
class MockGraphQlClient extends GraphQlClient {
  /// Indicator whether requests should throw [ConnectionException]s or not.
  ///
  /// Intended to be used to simulate a connection loss.
  bool _throwException = false;

  /// [Duration] to add to all requests simulating a delay.
  Duration? _delay;

  /// Indicates whether requests should throw [ConnectionException]s or not.
  bool get throwException => _throwException;

  /// Sets the indicator whether requests should throw [ConnectionException]s or
  /// not.
  set throwException(bool value) {
    _throwException = value;

    if (value) {
      disconnect();
    } else {
      reconnect();
    }

    connected.value = !value;
  }

  /// Returns the [Duration] to add to all requests simulating a delay.
  Duration? get delay => _delay;

  /// Sets the [Duration] to add to all requests simulating a delay.
  set delay(Duration? value) {
    connected.value = true;
    _delay = value;
  }

  @override
  Future<QueryResult> query(
    QueryOptions options, {
    RawClientOptions? raw,
    Exception Function(Map<String, dynamic>)? onException,
  }) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }

    if (throwException) {
      Log.debug(
        'query() -> throwing `ConnectionException` for $options',
        '$runtimeType',
      );

      connected.value = false;
      throw const ConnectionException('Mocked');
    }

    return super.query(options, raw: raw, onException: onException);
  }

  @override
  Future<QueryResult> mutate(
    MutationOptions options, {
    RawClientOptions? raw,
    Exception Function(Map<String, dynamic>)? onException,
  }) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }

    if (throwException) {
      Log.debug(
        'mutate() -> throwing `ConnectionException` for $options',
        '$runtimeType',
      );

      connected.value = false;
      throw const ConnectionException('Mocked');
    }

    return super.mutate(options, raw: raw, onException: onException);
  }

  @override
  Future<dio.Response<T>> post<T>(
    dynamic data, {
    dio.Options? options,
    String? operationName,
    Exception Function(Map<String, dynamic>)? onException,
    void Function(int, int)? onSendProgress,
    RawClientOptions? raw,
    dio.CancelToken? cancelToken,
  }) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }

    if (throwException) {
      Log.debug(
        'post() -> throwing `ConnectionException` for $data',
        '$runtimeType',
      );

      connected.value = false;
      throw const ConnectionException('Mocked');
    }

    return super.post(
      data,
      options: options,
      onException: onException,
      onSendProgress: onSendProgress,
      raw: raw,
      cancelToken: cancelToken,
    );
  }
}

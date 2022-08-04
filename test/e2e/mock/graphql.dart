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

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/provider/gql/base.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:mutex/mutex.dart';

/// Mocked [GraphQlProvider] containing its [MockGraphQlClient].
class MockGraphQlProvider extends GraphQlProvider {
  /// Mocked [GraphQlClient] itself.
  final MockGraphQlClient _client = MockGraphQlClient();

  @override
  MockGraphQlClient get client => _client;

  @override
  Mutex get clientGuard => _client.guard;

  @override
  AccessToken? get token => _client.token;

  @override
  set authExceptionHandler(Future<void> Function(AuthorizationException)? fn) =>
      _client.authExceptionHandler = fn;

  @override
  set token(AccessToken? value) => _client.token = value;

  @override
  void reconnect() => _client.reconnect();

  @override
  void disconnect() => _client.disconnect();

  @override
  void clearCache() => _client.clearCache();
}

/// Mocked [GraphQlClient] with an ability to add [delay] to its requests.
class MockGraphQlClient extends GraphQlClient {
  /// [Duration] to add to all requests simulating a delay.
  Duration? delay;

  /// Indicator whether requests should throw [ConnectionException]s or not.
  ///
  /// Intended to be used to simulate a connection loss.
  bool throwException = false;

  @override
  Future<QueryResult> query(
    QueryOptions options, [
    Exception Function(Map<String, dynamic>)? handleException,
  ]) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }

    if (throwException) {
      throw const ConnectionException('Mocked');
    }

    return super.query(options, handleException);
  }

  @override
  Future<QueryResult> mutate(
    MutationOptions options, {
    bool raw = false,
    Exception Function(Map<String, dynamic>)? onException,
  }) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }

    if (throwException) {
      throw const ConnectionException('Mocked');
    }

    return super.mutate(options, raw: raw, onException: onException);
  }

  @override
  Future<dio.Response<T>> post<T>(
    dynamic data, {
    dio.Options? options,
    Exception Function(Map<String, dynamic>)? onException,
    void Function(int, int)? onSendProgress,
  }) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }

    if (throwException) {
      throw const ConnectionException('Mocked');
    }

    return super.post(
      data,
      options: options,
      onException: onException,
      onSendProgress: onSendProgress,
    );
  }
}

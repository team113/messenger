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

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '/config.dart';
import '/provider/gql/exceptions.dart';
import 'log.dart';

/// Backoff algorithm helper.
class Backoff {
  /// Minimal [Duration] of the backoff.
  static const Duration _minBackoff = Duration(milliseconds: 500);

  /// Maximal [Duration] of the backoff.
  static const Duration _maxBackoff = Duration(milliseconds: 32000);

  /// Returns result of the provided [callback] using the exponential backoff
  /// algorithm on any errors.
  ///
  /// [retries] specified to `0` means infinite retrying.
  static Future<T> run<T>(
    FutureOr<T> Function() callback, {
    CancelToken? cancel,
    bool Function(Object e) retryIf = _defaultRetryIf,
    int retries = 0,
  }) async {
    int index = 0;

    final StackTrace invokedFrom = StackTrace.current;

    final CancelableOperation operation = CancelableOperation.fromFuture(
      Future(() async {
        Duration backoff = Duration.zero;

        while (true) {
          await Future.delayed(backoff);
          if (cancel?.isCancelled == true) {
            throw OperationCanceledException();
          }

          try {
            return await callback();
          } catch (e, _) {
            if (!retryIf(e)) {
              rethrow;
            }

            ++index;
            if (retries > 0 && index >= retries) {
              rethrow;
            }

            if (backoff.inMilliseconds == 0) {
              backoff = _minBackoff;
            } else if (backoff < _maxBackoff) {
              backoff *= 2;
            }

            Log.debug('$e\n$invokedFrom', 'Backoff');
          }
        }
      }),
    );

    cancel?.whenCancel.then((_) => operation.cancel());

    final result = await operation.valueOrCancellation();
    if (operation.isCanceled) {
      throw OperationCanceledException();
    }

    return result;
  }

  /// Returns `true`.
  static bool _defaultRetryIf(Object _) => true;
}

/// Exception of a [Backoff] operating being manually canceled.
class OperationCanceledException implements Exception {}

/// Exception of network being unreachable for some reason.
class UnreachableException implements Exception {
  @override
  String toString() =>
      'UnreachableException: Unable to send request to the server (`${Config.url}:${Config.port}${Config.graphql}`)';
}

/// Extension adding getter to check whether [Object] is a network related
/// [Exception].
extension ObjectIsNetworkRelatedException on Object {
  /// Indicates whether this [Object] is a network related [Exception].
  bool get isNetworkRelated {
    return this is ConnectionException ||
        this is SocketException ||
        this is WebSocketException ||
        this is WebSocketChannelException ||
        this is HttpException ||
        this is ClientException ||
        this is DioException ||
        this is TimeoutException ||
        this is ResubscriptionRequiredException ||
        this is ConnectionException;
  }
}

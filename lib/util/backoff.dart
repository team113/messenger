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

import 'dart:async';

import 'package:async/async.dart';
import 'package:dio/dio.dart';

import 'log.dart';

/// Backoff algorithm helper.
class Backoff {
  /// Minimal [Duration] of the backoff.
  static const Duration _minBackoff = Duration(milliseconds: 500);

  /// Maximal [Duration] of the backoff.
  static const Duration _maxBackoff = Duration(milliseconds: 32000);

  /// Returns result of the provided [callback] using the exponential backoff
  /// algorithm on any errors.
  static Future<T> run<T>(
    Future<T> Function() callback, [
    CancelToken? cancelToken,
  ]) async {
    final CancelableOperation operation = CancelableOperation.fromFuture(
      Future(() async {
        Duration backoff = Duration.zero;

        while (true) {
          await Future.delayed(backoff);
          if (cancelToken?.isCancelled == true) {
            throw OperationCanceledException();
          }

          try {
            return await callback();
          } catch (e) {
            if (backoff.inMilliseconds == 0) {
              backoff = _minBackoff;
            } else if (backoff < _maxBackoff) {
              backoff *= 2;
            }

            if (e is Exception) {
              Log.error(e.toString());
            } else {
              Log.error(e);
            }
          }
        }
      }),
    );

    cancelToken?.whenCancel.then((_) => operation.cancel());

    final result = await operation.valueOrCancellation();
    if (operation.isCanceled) {
      throw OperationCanceledException();
    }

    return result;
  }
}

/// Exception of a [Backoff] operating being manually canceled.
class OperationCanceledException implements Exception {}

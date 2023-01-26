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

import 'package:dio/dio.dart';
import 'package:get/get.dart';

/// Helper to execute methods with backoff algorithm.
class Backoff {
  /// Backoff delays of the operations.
  static final Map<String, Duration> _backoffs = {};

  /// [Timer]s resetting the [_backoffs].
  static final Map<String, Timer> _resetTimers = {};

  /// Maximal [Duration] of the backoff.
  static final Duration _maxBackoff = 64.seconds;

  /// Returns delay for an operation with the provided [key].
  static Duration get(String key) {
    _resetTimers[key]?.cancel();

    Duration backoff = _backoffs[key] ?? Duration.zero;

    _backoffs[key] = increaseBackoff(backoff);
    _resetTimers[key] = Timer(
      const Duration(seconds: 10),
      () => _backoffs[key] = Duration.zero,
    );

    return backoff;
  }

  /// Calls the provided [callback] using the exponential backoff algorithm.
  static Future<T> run<T>(
    Future<T> Function() callback, [
    CancelToken? cancelToken,
  ]) async {
    Duration backoff = Duration.zero;

    while (true) {
      try {
        await Future.delayed(backoff);

        if (cancelToken?.isCancelled == true) {
          throw OperationCanceledException();
        }

        return await callback();
      } catch (e) {
        if (e is OperationCanceledException) {
          rethrow;
        }

        backoff = increaseBackoff(backoff);
      }
    }
  }

  /// Increases the provided [backoff].
  static Duration increaseBackoff(Duration backoff) {
    if (backoff.inMilliseconds == 0) {
      backoff = 125.milliseconds;
    } else if (backoff < _maxBackoff) {
      backoff *= 2;
    }

    return backoff;
  }
}

/// Exception indicates that operation has been canceled.
class OperationCanceledException implements Exception {}

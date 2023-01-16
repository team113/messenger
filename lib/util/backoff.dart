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

import 'package:dio/dio.dart';
import 'package:get/get.dart';

/// Helper to execute methods with backoff algorithm.
class Backoff {
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
      } catch (_) {
        if (backoff.inMilliseconds == 0) {
          backoff = 125.milliseconds;
        } else if (backoff < 64.seconds) {
          backoff *= 2;
        }
      }
    }
  }
}

/// Exception indicates that operation has been canceled.
class OperationCanceledException implements Exception {}

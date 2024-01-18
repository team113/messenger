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

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:mutex/mutex.dart';

import '/util/backoff.dart';

/// Utility limiting [Function] invokes to [requests] per the specified [per].
class RateLimiter {
  RateLimiter({
    this.requests = 5,
    this.per = const Duration(seconds: 1),
  });

  /// Requests allowed to be invoked in [per].
  final int requests;

  /// [Duration], per which the specified number of [requests] should be made.
  final Duration per;

  /// [Queue] of [Mutex]es locking the functions invoked.
  @visibleForTesting
  final Queue<Mutex> queue = Queue();

  /// [Timer] unlocking the [queue] periodically.
  Timer? _timer;

  /// Iteration of this [RateLimiter], used to ignore queued functions, when
  /// [clear] is invoked.
  int _iteration = 0;

  /// Executes the [function] limited to the [requests] per [per].
  Future<T> execute<T>(FutureOr<T> Function() function) async {
    // Current [_iteration] to ignore the invoke, if mismatched.
    int iteration = _iteration;

    // Start the [Timer] reducing the [_queue].
    _timer ??= Timer.periodic(
      per,
      (_) {
        // Remove unlocked [Mutex]es.
        queue.removeWhere((e) => !e.isLocked);

        if (queue.isEmpty) {
          _timer?.cancel();
          _timer = null;
          return;
        }

        final taken = queue.take(requests);
        for (var m in taken) {
          m.release();
        }
      },
    );

    final Mutex mutex = Mutex();
    queue.add(mutex);

    if (queue.length > requests) {
      await mutex.acquire();
    }

    await mutex.acquire();
    try {
      if (iteration != _iteration) {
        throw OperationCanceledException();
      }

      if (function is T) {
        return function();
      }

      return await function();
    } finally {
      if (mutex.isLocked) {
        mutex.release();
      }
    }
  }

  /// Clears this [RateLimiter].
  void clear() {
    ++_iteration;

    _timer?.cancel();
    _timer = null;

    for (var m in queue) {
      if (m.isLocked) {
        m.release();
      }
    }

    queue.clear();
  }
}

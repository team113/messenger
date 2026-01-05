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

import 'package:mutex/mutex.dart';

/// Helper guarding synchronized access for processing [T] objects.
class EventPool<T> {
  /// [Mutex]es guarding access to the [protect] method.
  final Map<T, _PoolMutex> _mutexes = {};

  /// List of [T] objects that have been processed.
  final List<Object> _processed = [];

  /// Indicator whether this [EventPool] has been disposed.
  bool _disposed = false;

  /// Disposes this [EventPool].
  void dispose() {
    _disposed = true;
  }

  /// Executes the provided [callback], locking its execution with the provided
  /// [tag].
  ///
  /// Does nothing, if [tag] is already locked, meaning being executed by
  /// another [callback].
  ///
  /// If [repeat] is provided, then the [callback] will be invoked in loop,
  /// while [repeat] returns `true`.
  ///
  /// If [values] are provided, then [lockedWith] shall return `true` only if
  /// [values] contain the specified there value.
  Future<void> protect(
    T tag,
    Future<void> Function() callback, {
    FutureOr<bool> Function()? repeat,
    List<Object?> values = const [],
  }) async {
    _PoolMutex? mutex = _mutexes[tag];
    if (mutex == null) {
      mutex = _PoolMutex();
      _mutexes[tag] = mutex;
    }

    if (!mutex.isLocked) {
      mutex.values = values;
      do {
        await mutex.protect(callback);
      } while (!_disposed && await repeat?.call() == true);
    }
  }

  /// Adds the provided [object] to the list of processed objects.
  void add(Object object) => _processed.add(object);

  /// Indicates whether the provided [object] has been processed, popping it.
  bool processed(Object object) => _processed.remove(object);

  /// Indicates whether an object with the provided [tag] and [value] is being
  /// executed.
  bool lockedWith(T tag, Object? value) {
    final _PoolMutex? mutex = _mutexes[tag];
    return mutex != null &&
        mutex.isLocked == true &&
        mutex.values.contains(value);
  }
}

/// Wrapper around [Mutex] with the values associated with it.
class _PoolMutex {
  _PoolMutex();

  /// [Mutex] of this [_PoolMutex].
  final Mutex mutex = Mutex();

  /// Values associated with the [mutex].
  List<Object?> values = [];

  /// Indicates whether the lock has been acquired and isn't released.
  bool get isLocked => mutex.isLocked;

  /// Guards the [criticalSection] allowing ony synchronized execution of it.
  Future<T> protect<T>(Future<T> Function() criticalSection) =>
      mutex.protect(criticalSection);
}

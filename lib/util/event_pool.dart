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

import 'package:mutex/mutex.dart';

/// Helper for managing processed [T] objects.
class EventPool<T> {
  /// [Mutex]es guarding access to the [protect] method.
  final Map<T, _PoolMutex> _mutexes = {};

  /// List of [T] events that have been processed.
  final List<Object> _processed = [];

  /// Executes the provided [callback], locking its execution with the provided
  /// [tag].
  ///
  /// Does nothing, if [tag] is already locked, meaning being executed by
  /// another [callback].
  ///
  /// If [repeat] is provided, then the [callback] will be invoked in loop,
  /// while [repeat] returns `true`.
  Future<void> protect(
    T tag,
    Future<void> Function() callback, {
    bool Function()? repeat,
  }) async {
    if (_mutexes[tag] == null) {
      _mutexes[tag] = _PoolMutex(Mutex());
    }

    final Mutex mutex = _mutexes[tag]!.mutex;
    if (!mutex.isLocked) {
      do {
        await mutex.protect(callback);
      } while (repeat?.call() ?? false);
    }
  }

  /// Adds the provided [event] to the list of processed events.
  void add(Object event) => _processed.add(event);

  /// Indicates whether the provided [event] has been processed.
  bool processed(Object event, {bool remove = true}) =>
      (remove ? _processed.remove : _processed.contains).call(event);

  /// Associates the provided [values] with the [Mutex] by the provided [tag].
  void lockWith(T tag, List<Object?> values) => _mutexes[tag]?.values = values;

  /// Indicates whether an event with the provided [tag] and [value] is being
  /// executed.
  bool lockedWith(T tag, Object? value) =>
      _mutexes[tag]?.mutex.isLocked == true &&
      _mutexes[tag]!.values.contains(value);
}

/// Wrapper around [Mutex] with a values associated with it.
class _PoolMutex {
  _PoolMutex(this.mutex);

  /// [Mutex] of this [_PoolMutex].
  final Mutex mutex;

  /// Values associated with the [mutex].
  List<Object?> values = [];
}

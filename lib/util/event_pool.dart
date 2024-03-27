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

/// Helper for managing processed events.
class EventPool<T> {
  /// [Mutex]es guarding access to the [protect] method.
  final Map<T, Mutex> _mutexes = {};

  /// List of events that have been processed.
  final List<Object> _processed = [];

  /// Protects the provided [callback] by a [Mutex] with the provided [tag].
  ///
  /// Does nothing if [Mutex] is already locked.
  Future<void> protect(
    T tag,
    Future<void> Function() callback, {
    required bool Function() repeat,
  }) async {
    if (_mutexes[tag] == null) {
      _mutexes[tag] = Mutex();
    }

    Mutex mutex = _mutexes[tag]!;

    if (!mutex.isLocked) {
      do {
        await mutex.protect(callback);
      } while (repeat());
    }
  }

  /// Adds the provided [event] to the list of processed events.
  void add(Object event) => _processed.add(event);

  /// Indicates whether the provided [event] has been processed.
  bool processed(Object event) => _processed.remove(event);

  /// Indicates whether [Mutex] with the provided [tag] is locked.
  bool locked(T tag) => _mutexes[tag]?.isLocked == true;
}

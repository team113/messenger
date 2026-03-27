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

import 'map.dart';

export 'list.dart';
export 'map.dart';
export 'rx_sorted_map.dart';
export 'rxlist.dart';
export 'rxmap.dart';
export 'rxsplay.dart';
export 'sorted_map.dart';

/// Possible operation kinds changing an observable iterable.
enum OperationKind { added, removed, updated }

/// Extension adding an ability to get [MapChangeNotification]s from [Stream].
extension MapChangesExtension<K, T> on Stream<Map<K, T>> {
  /// Gets [MapChangeNotification]s from [Stream].
  Stream<List<MapChangeNotification<K, T>>> changes() {
    Map<K, T> last = {};
    bool first = true;

    return asyncExpand((e) async* {
      final List<MapChangeNotification<K, T>> changed = [];

      for (final MapEntry<K, T> entry in e.entries) {
        final T? item = last[entry.key];
        if (item == null) {
          changed.add(MapChangeNotification.added(entry.key, entry.value));
        } else {
          if (entry.value != item) {
            changed.add(
              MapChangeNotification.updated(entry.key, entry.key, entry.value),
            );
          }
        }
      }

      for (final MapEntry<K, T> entry in last.entries) {
        final T? item = e[entry.key];
        if (item == null) {
          changed.add(MapChangeNotification.removed(entry.key, entry.value));
        }
      }

      last = Map.from(e);

      // Always emit the first changes, even if they are empty.
      if (first) {
        first = false;
        yield changed;
      } else if (changed.isNotEmpty) {
        yield changed;
      }
    });
  }
}

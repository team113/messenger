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

import 'dart:collection';

import 'map.dart';

/// Automatically sorted observable [Map].
class SortedObsMap<K, V> extends MapMixin<K, V> {
  SortedObsMap(this.compare);

  /// Callback, comparing the provided [V] items.
  final int Function(V, V) compare;

  /// [Map] maintains an O(1) complexity for getting elements.
  ///
  /// Removing item by [K] is O(1)
  final ObsMap<K, V> _keys = ObsMap();

  /// [SplayTreeSet] returns the sorted [V] values.
  late final SplayTreeSet<V> _values = SplayTreeSet(compare);

  /// Unsorted [K] keys.
  @override
  Iterable<K> get keys => _keys.keys;

  @override
  Iterable<V> get values => _values;

  @override
  bool get isEmpty => _values.isEmpty;

  @override
  bool get isNotEmpty => _values.isNotEmpty;

  @override
  int get length => _values.length;

  /// First [V] item.
  V get first => _values.first;

  /// Last [V] item.
  V get last => _values.last;

  /// Returns stream of record of changes of this [SortedObsMap].
  Stream<MapChangeNotification<K, V>> get changes => _keys.changes;

  @override
  operator []=(K key, V value) {
    _values.remove(_keys[key]);

    _keys[key] = value;
    _values.add(value);
  }

  @override
  V? operator [](Object? key) => _keys[key];

  @override
  V? remove(Object? key) {
    V? removed = _keys.remove(key);
    _values.remove(removed);

    return removed;
  }

  @override
  void clear() {
    _keys.clear();
    _values.clear();
  }
}

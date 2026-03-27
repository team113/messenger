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

import 'dart:collection';

import 'map.dart';

/// Self-sorting observable [Map].
///
/// Please note that [V] values must implement [Comparable], otherwise adding or
/// removing of the items can behave in an unexpected way.
class SortedObsMap<K, V> extends MapMixin<K, V> {
  SortedObsMap([Comparator<V>? compare])
    : _compare = compare ?? _defaultCompare<V>();

  /// Callback, comparing the provided [V] items.
  final Comparator<V> _compare;

  /// [Map] for an constant complexity for getting elements by its keys.
  final ObsMap<K, V> _keys = ObsMap();

  /// [SplayTreeSet] of the sorted [V] values.
  late final SplayTreeSet<V> _values = SplayTreeSet(_compare);

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
    _values.add(value);
    _keys[key] = value;
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

  /// Returns a [Comparator] for the provided [V].
  static Comparator<V> _defaultCompare<V>() {
    // If [V] is [Comparable], then just return it.
    Object compare = Comparable.compare;
    if (compare is Comparator<V>) {
      return compare;
    }

    return (_, _) => -1;
  }
}

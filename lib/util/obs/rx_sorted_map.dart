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

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'map.dart';
import 'sorted_map.dart';

/// `GetX`-reactive [SortedObsMap].
class RxSortedObsMap<K, V> extends MapMixin<K, V>
    with NotifyManager<SortedObsMap<K, V>>, RxObjectMixin<SortedObsMap<K, V>>
    implements RxInterface<SortedObsMap<K, V>> {
  RxSortedObsMap() : _value = SortedObsMap<K, V>();

  /// Internal actual value of the [SortedObsMap] this [RxSortedObsMap] holds.
  late final SortedObsMap<K, V> _value;

  /// Returns stream of record of changes of this [RxSortedObsMap].
  Stream<MapChangeNotification<K, V>> get changes => _value.changes;

  @override
  V? operator [](Object? key) => value[key as K?];

  @override
  void operator []=(K key, V value) {
    _value[key] = value;
    refresh();
  }

  @override
  void clear() {
    _value.clear();
    refresh();
  }

  @override
  Iterable<K> get keys => value.keys;

  @override
  Iterable<V> get values => value.values;

  @override
  V? remove(Object? key) {
    final val = _value.remove(key);
    refresh();
    return val;
  }

  @override
  @protected
  SortedObsMap<K, V> get value {
    RxInterface.proxy?.addListener(subject);
    return _value;
  }
}

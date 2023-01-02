// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

/// `GetX`-reactive [ObsMap].
///
/// Behaves like a wrapper around [Map] with its [changes] exposed.
class RxObsMap<K, V> extends MapMixin<K, V>
    with NotifyManager<ObsMap<K, V>>, RxObjectMixin<ObsMap<K, V>>
    implements RxInterface<ObsMap<K, V>> {
  /// Creates a new [LinkedHashMap] with the provided [initial] keys and values.
  RxObsMap([Map<K, V> initial = const {}])
      : _value = ObsMap<K, V>.from(initial);

  /// Creates a new [LinkedHashMap] with the same keys and values as [other].
  factory RxObsMap.from(Map<K, V> other) => RxObsMap(Map<K, V>.from(other));

  /// Creates a new [LinkedHashMap] with the same keys and values as [other].
  factory RxObsMap.of(Map<K, V> other) => RxObsMap(Map<K, V>.of(other));

  /// Creates an unmodifiable hash based map containing the entries of [other].
  factory RxObsMap.unmodifiable(Map<dynamic, dynamic> other) =>
      RxObsMap(Map<K, V>.unmodifiable(other));

  /// Creates a new [LinkedHashMap] instance in which the keys and values are
  /// computed from the provided [iterable].
  factory RxObsMap.fromIterable(
    Iterable iterable, {
    K Function(dynamic element)? key,
    V Function(dynamic element)? value,
  }) =>
      RxObsMap(Map<K, V>.fromIterable(iterable, key: key, value: value));

  /// Creates a new [LinkedHashMap] associating the given [keys] to the given
  /// [values].
  factory RxObsMap.fromIterables(Iterable<K> keys, Iterable<V> values) =>
      RxObsMap(Map<K, V>.fromIterables(keys, values));

  /// Creates a new [LinkedHashMap] and adds all the provided [entries] to it.
  factory RxObsMap.fromEntries(Iterable<MapEntry<K, V>> entries) =>
      RxObsMap(Map<K, V>.fromEntries(entries));

  /// Internal actual value of the [ObsMap] this [RxObsMap] holds.
  late ObsMap<K, V> _value;

  /// Returns stream of record of changes of this [RxObsMap].
  Stream<MapChangeNotification<K, V>> get changes => _value.changes;

  /// Emits a new [event].
  ///
  /// May be used to explicitly notify the listeners of the [changes].
  void emit(MapChangeNotification<K, V> event) {
    _value.emit(event);
    refresh();
  }

  @override
  V? operator [](Object? key) => value[key as K];

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
  V? remove(Object? key) {
    final val = _value.remove(key);
    refresh();
    return val;
  }

  /// Moves the element at the [oldKey] to the [newKey] replacing the existing
  /// element, if any.
  ///
  /// No-op, if element at the [oldKey] doesn't exist.
  void move(K oldKey, K newKey) {
    _value.move(oldKey, newKey);
    refresh();
  }

  @override
  @protected
  ObsMap<K, V> get value {
    RxInterface.proxy?.addListener(subject);
    return _value;
  }
}

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
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'obs.dart';

/// `GetX`-reactive [SplayTreeMap].
///
/// Behaves like a wrapper around [SplayTreeMap].
class RxObsSplayTreeMap<K, V>
    with
        MapMixin<K, V>,
        NotifyManager<SplayTreeMap<K, V>>,
        RxObjectMixin<SplayTreeMap<K, V>>
    implements RxInterface<SplayTreeMap<K, V>> {
  /// Creates a new [SplayTreeMap] with the provided [initial] keys and values.
  RxObsSplayTreeMap([Map<K, V> initial = const {}])
    : _value = SplayTreeMap.from(initial);

  /// Creates a new [SplayTreeMap] with the same keys and values as [other].
  factory RxObsSplayTreeMap.from(Map<K, V> other) =>
      RxObsSplayTreeMap(Map.from(other));

  /// Creates a new [SplayTreeMap] with the same keys and values as [other].
  factory RxObsSplayTreeMap.of(Map<K, V> other) =>
      RxObsSplayTreeMap(Map.of(other));

  /// Creates an unmodifiable hash based map containing the entries of [other].
  factory RxObsSplayTreeMap.unmodifiable(Map<dynamic, dynamic> other) =>
      RxObsSplayTreeMap(Map.unmodifiable(other));

  /// Creates a new [SplayTreeMap] instance in which the keys and values are
  /// computed from the provided [iterable].
  factory RxObsSplayTreeMap.fromIterable(
    Iterable iterable, {
    K Function(dynamic element)? key,
    V Function(dynamic element)? value,
  }) => RxObsSplayTreeMap(
    Map<K, V>.fromIterable(iterable, key: key, value: value),
  );

  /// Creates a new [SplayTreeMap] associating the given [keys] to the given
  /// [values].
  factory RxObsSplayTreeMap.fromIterables(
    Iterable<K> keys,
    Iterable<V> values,
  ) => RxObsSplayTreeMap(Map<K, V>.fromIterables(keys, values));

  /// Creates a new [SplayTreeMap] and adds all the provided [entries] to it.
  factory RxObsSplayTreeMap.fromEntries(Iterable<MapEntry<K, V>> entries) =>
      RxObsSplayTreeMap(Map<K, V>.fromEntries(entries));

  /// Internal actual value of the [SplayTreeMap] this [RxObsSplayTreeMap] holds.
  late SplayTreeMap<K, V> _value;

  /// [StreamController] of record of changes of this [ObsMap].
  final _changes = StreamController<MapChangeNotification<K, V>>.broadcast(
    sync: true,
  );

  /// Returns stream of record of changes of this [ObsMap].
  Stream<MapChangeNotification<K, V>> get changes => _changes.stream;

  @override
  bool get isEmpty => _value.isEmpty;

  @override
  bool get isNotEmpty => _value.isNotEmpty;

  @override
  int get length => _value.length;

  @override
  Iterable<K> get keys => _value.keys;

  @override
  Iterable<V> get values => _value.values;

  @override
  Iterable<MapEntry<K, V>> get entries => _value.entries;

  /// Emits a new [event].
  ///
  /// May be used to explicitly notify the listeners of the [changes].
  void emit(MapChangeNotification<K, V> event) => _changes.add(event);

  @override
  V? operator [](Object? key) => _value[key];

  @override
  V? remove(Object? key) {
    V? result = _value.remove(key);
    if (result != null) {
      _changes.add(MapChangeNotification<K, V>.removed(key as K?, result));
    }
    refresh();
    return result;
  }

  @override
  void operator []=(K key, V value) {
    if (super.containsKey(key)) {
      _value[key] = value;
      _changes.add(MapChangeNotification<K, V>.updated(key, key, value));
    } else {
      _value[key] = value;
      _changes.add(MapChangeNotification<K, V>.added(key, value));
    }
    refresh();
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    V result = _value.putIfAbsent(key, ifAbsent);
    refresh();
    return result;
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    V result = _value.update(key, update, ifAbsent: ifAbsent);
    refresh();
    return result;
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    _value.updateAll(update);
    refresh();
  }

  @override
  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      _changes.add(MapChangeNotification<K, V>.added(key, value));
      this[key] = value;
    });
  }

  @override
  void forEach(void Function(K key, V value) action) {
    _value.forEach(action);
    refresh();
  }

  @override
  void clear() {
    for (var entry in entries) {
      _changes.add(MapChangeNotification<K, V>.removed(entry.key, entry.value));
    }
    _value.clear();
    refresh();
  }

  @override
  bool containsKey(Object? key) => _value.containsKey(key);

  @override
  bool containsValue(Object? value) => _value.containsValue(value);

  /// Returns the first key of this [RxObsSplayTreeMap].
  K? firstKey() => _value.firstKey();

  /// Returns the last key of this [RxObsSplayTreeMap].
  K? lastKey() => _value.lastKey();

  /// Returns the key preceding the provided [key].
  K? lastKeyBefore(K key) => _value.lastKeyBefore(key);

  /// Returns the key following the provided [key].
  K? firstKeyAfter(K key) => _value.firstKeyAfter(key);

  @override
  @protected
  SplayTreeMap<K, V> get value {
    RxInterface.proxy?.addListener(subject);
    return _value;
  }
}

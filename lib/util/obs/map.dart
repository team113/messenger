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

import 'dart:async';

import 'package:collection/collection.dart';

import 'obs.dart';

/// Observable reactive map.
///
/// Behaves like a wrapper around [Map] with its [changes] exposed.
class ObsMap<K, V> extends DelegatingMap<K, V> implements Map<K, V> {
  /// Creates a [LinkedHashMap] with [initial] keys and values.
  ObsMap([Map<K, V>? initial]) : super(initial ?? {});

  /// Creates a [LinkedHashMap] with the same keys and values as [other].
  factory ObsMap.from(Map other) => ObsMap(Map<K, V>.from(other));

  /// Creates a [LinkedHashMap] with the same keys and values as [other].
  factory ObsMap.of(Map<K, V> other) => ObsMap(Map<K, V>.of(other));

  /// Creates an unmodifiable hash-based map containing the entries of [other].
  factory ObsMap.unmodifiable(ObsMap<K, V> other) =>
      ObsMap(Map<K, V>.unmodifiable(other));

  /// Creates a Map instance in which the keys and values are computed from the
  /// [iterable].
  factory ObsMap.fromIterable(
    Iterable iterable, {
    K Function(dynamic element)? key,
    V Function(dynamic element)? value,
  }) =>
      ObsMap(Map<K, V>.fromIterable(iterable, key: key, value: value));

  /// Creates a map associating the given [keys] to the given [values].
  factory ObsMap.fromIterables(Iterable<K> keys, Iterable<V> values) =>
      ObsMap(Map<K, V>.fromIterables(keys, values));

  /// Creates a new map and adds all the provided [entries] to it.
  factory ObsMap.fromEntries(Iterable<MapEntry<K, V>> entries) =>
      ObsMap(Map<K, V>.fromEntries(entries));

  /// [StreamController] of record of changes of this [ObsMap].
  final _changes = StreamController<MapChangeNotification<K, V>>.broadcast();

  /// Returns stream of record of changes of this [ObsMap].
  Stream<MapChangeNotification<K, V>> get changes => _changes.stream;

  /// Emits a new [event].
  ///
  /// May be used to explicitly notify the listeners of the [changes].
  void emit(MapChangeNotification<K, V> event) => _changes.add(event);

  @override
  void operator []=(K key, V value) {
    if (super.containsKey(key)) {
      super[key] = value;
      _changes.add(MapChangeNotification<K, V>.updated(key, key, value));
    } else {
      super[key] = value;
      _changes.add(MapChangeNotification<K, V>.added(key, value));
    }
  }

  @override
  void addAll(Map<K, V> other) => addEntries(other.entries);

  @override
  void addEntries(Iterable<MapEntry<K, V>> entries) {
    for (var element in entries) {
      if (super.containsKey(element.key)) {
        super[element.key] = element.value;
        _changes.add(MapChangeNotification<K, V>.updated(
            element.key, element.key, element.value));
      } else {
        super[element.key] = element.value;
        _changes
            .add(MapChangeNotification<K, V>.added(element.key, element.value));
      }
    }
  }

  @override
  void clear() {
    for (var entry in entries) {
      _changes.add(MapChangeNotification<K, V>.removed(entry.key, entry.value));
    }
    super.clear();
  }

  @override
  V? remove(Object? key) {
    V? v = super.remove(key);
    if (v != null) {
      _changes.add(MapChangeNotification<K, V>.removed(key as K?, v));
    }
    return v;
  }

  /// Moves the element at the [oldKey] to the [newKey] replacing the existing
  /// element, if any.
  ///
  /// No-op, if element at the [oldKey] doesn't exist.
  void move(K oldKey, K newKey) {
    V? v = super.remove(oldKey);

    if (v != null) {
      V? n = super[newKey];
      if (n != null && n != v) {
        _changes.add(MapChangeNotification<K, V>.removed(newKey, n));
      }

      super[newKey] = v;
      _changes.add(MapChangeNotification<K, V>.updated(newKey, oldKey, v));
    }
  }
}

/// Change in an [ObsMap].
class MapChangeNotification<K, V> {
  /// Returns notification with [op] operation.
  MapChangeNotification(this.key, this.oldKey, this.value, this.op);

  /// Returns notification with [OperationKind.added] operation.
  MapChangeNotification.added(this.key, this.value)
      : op = OperationKind.added,
        oldKey = null;

  /// Returns notification with [OperationKind.updated] operation.
  MapChangeNotification.updated(this.key, this.oldKey, this.value)
      : op = OperationKind.updated;

  /// Returns notification with [OperationKind.removed] operation.
  MapChangeNotification.removed(this.key, this.value)
      : op = OperationKind.removed,
        oldKey = null;

  /// Key of the changed element.
  final K? key;

  /// Previous key the changed element had.
  final K? oldKey;

  /// Value of the changed element.
  final V? value;

  /// Operation causing the [element] to change.
  final OperationKind op;
}

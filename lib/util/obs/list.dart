// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

/// Observable reactive list.
///
/// Behaves like a wrapper around [List] with its [changes] exposed.
class ObsList<E> extends DelegatingList<E> implements List<E> {
  /// Creates a list with [initial] values.
  ObsList([List<E>? initial]) : super(initial ?? []);

  /// Creates a list of the given length with [fill] at each position.
  factory ObsList.filled(int length, E fill, {bool growable = false}) =>
      ObsList(List<E>.filled(length, fill, growable: growable));

  /// Creates a list containing all the provided [elements].
  factory ObsList.from(Iterable<E> elements, {bool growable = true}) =>
      ObsList(List<E>.from(elements, growable: growable));

  /// Creates a list from the provided [elements].
  ///
  /// The [Iterator] of [elements] provides their order.
  ///
  /// This constructor creates a growable list when [growable] is `true`;
  /// otherwise, it returns a fixed-length list.
  factory ObsList.of(Iterable<E> elements, {bool growable = true}) =>
      ObsList(List<E>.of(elements, growable: growable));

  /// Generates a list of values.
  ///
  /// Creates a list with [length] positions and fills it with values created by
  /// calling [generator] for each index in the range `0` .. `length - 1`
  /// in increasing order.
  /// ```dart
  /// List<int>.generate(3, (int index) => index * index); // [0, 1, 4]
  /// ```
  /// The created list is fixed-length if [growable] is set to `false`.
  ///
  /// The [length] must be non-negative.
  factory ObsList.generate(
    int length,
    E Function(int index) generator, {
    bool growable = true,
  }) =>
      ObsList(List<E>.generate(length, generator, growable: growable));

  /// Creates an unmodifiable list containing all the provided [elements].
  ///
  /// The [Iterator] of [elements] provides their order.
  ///
  /// An unmodifiable list cannot have its length or elements changed.
  /// If the [elements] are themselves immutable, then the resulting list
  /// is also immutable.
  factory ObsList.unmodifiable(Iterable elements) =>
      ObsList(List<E>.unmodifiable(elements));

  /// [StreamController] of changes of this list.
  final _changes = StreamController<ListChangeNotification<E>>.broadcast();

  /// Returns stream of changes of this list.
  Stream<ListChangeNotification<E>> get changes => _changes.stream;

  /// Emits a new [event].
  ///
  /// May be used to explicitly notify the listeners of the [changes].
  void emit(ListChangeNotification<E> event) => _changes.add(event);

  @override
  operator []=(int index, E value) {
    super[index] = value;
    _changes.add(ListChangeNotification<E>.updated(value, index));
  }

  @override
  void add(E value) {
    super.add(value);
    _changes.add(ListChangeNotification<E>.added(value, length - 1));
  }

  @override
  void addAll(Iterable<E> iterable) {
    super.addAll(iterable);
    for (var element in iterable) {
      _changes.add(ListChangeNotification<E>.added(element, length - 1));
    }
  }

  @override
  void insert(int index, E element) {
    super.insert(index, element);
    _changes.add(ListChangeNotification<E>.added(element, index));
  }

  @override
  bool remove(Object? value) {
    int pos = indexOf(value as E);
    bool hasRemoved = super.remove(value);
    if (hasRemoved) {
      _changes.add(ListChangeNotification<E>.removed(value, pos));
    }
    return hasRemoved;
  }

  @override
  E removeAt(int index) {
    E removed = super.removeAt(index);
    _changes.add(ListChangeNotification<E>.removed(removed, index));
    return removed;
  }

  @override
  void removeWhere(bool Function(E p1) test) {
    var stored = List<E>.from(this, growable: false);

    super.removeWhere(test);
    for (int i = 0; i < stored.length; ++i) {
      if (!contains(stored[i])) {
        _changes.add(ListChangeNotification<E>.removed(stored[i], i));
      }
    }
  }

  @override
  void clear() {
    for (int i = 0; i < length; ++i) {
      _changes.add(ListChangeNotification<E>.removed(this[i], length));
    }
    super.clear();
  }
}

/// Change in an [ObsList].
class ListChangeNotification<E> {
  /// Returns notification with [op] operation.
  ListChangeNotification(this.element, this.op, this.pos);

  /// Returns notification with [OperationKind.added] operation.
  ListChangeNotification.added(this.element, this.pos)
      : op = OperationKind.added;

  /// Returns notification with [OperationKind.updated] operation.
  ListChangeNotification.updated(this.element, this.pos)
      : op = OperationKind.updated;

  /// Returns notification with [OperationKind.removed] operation.
  ListChangeNotification.removed(this.element, this.pos)
      : op = OperationKind.removed;

  /// Element being changed.
  final E element;

  /// Operation causing the [element] to change.
  final OperationKind op;

  /// Position of the changed [element].
  final int pos;
}

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

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'list.dart';

/// `GetX`-reactive [ObsList].
///
/// Behaves like a wrapper around [List] with its [changes] exposed.
class RxObsList<E> extends ListMixin<E>
    with NotifyManager<ObsList<E>>, RxObjectMixin<ObsList<E>>
    implements RxInterface<ObsList<E>> {
  /// Creates a new list with the provided [initial] values.
  RxObsList([List<E> initial = const []]) : _value = ObsList<E>.from(initial);

  /// Creates a new list of the given length with the provided [fill] element at
  /// each position.
  factory RxObsList.filled(int length, E fill, {bool growable = false}) =>
      RxObsList(List<E>.filled(length, fill, growable: growable));

  /// Creates an empty list.
  factory RxObsList.empty({bool growable = false}) =>
      RxObsList(List<E>.empty(growable: growable));

  /// Creates a new list containing all the provided [elements].
  factory RxObsList.from(Iterable elements, {bool growable = true}) =>
      RxObsList(List<E>.from(elements, growable: growable));

  /// Creates a list from the provided [elements].
  factory RxObsList.of(Iterable<E> elements, {bool growable = true}) =>
      RxObsList(List<E>.of(elements, growable: growable));

  /// Generates a list of values.
  factory RxObsList.generate(int length, E Function(int index) generator,
          {bool growable = true}) =>
      RxObsList(List<E>.generate(length, generator, growable: growable));

  /// Creates an unmodifiable list containing all the provided [elements].
  factory RxObsList.unmodifiable(Iterable elements) =>
      RxObsList(List<E>.unmodifiable(elements));

  /// Internal actual value of the [ObsList] this [RxObsMap] holds.
  late ObsList<E> _value;

  @override
  Iterator<E> get iterator => value.iterator;

  /// Returns stream of record of changes of this [RxObsList].
  Stream<ListChangeNotification<E>> get changes => _value.changes;

  /// Emits a new [event].
  ///
  /// May be used to explicitly notify the listeners of the [changes].
  void emit(ListChangeNotification<E> event) {
    _value.emit(event);
    refresh();
  }

  @override
  void operator []=(int index, E val) {
    _value[index] = val;
    refresh();
  }

  @override
  RxObsList<E> operator +(Iterable<E> other) {
    addAll(other);
    refresh();
    return this;
  }

  @override
  E operator [](int index) {
    return value[index];
  }

  @override
  void add(E element) {
    _value.add(element);
    refresh();
  }

  @override
  void addAll(Iterable<E> iterable) {
    _value.addAll(iterable);
    refresh();
  }

  @override
  void removeWhere(bool Function(E element) test) {
    _value.removeWhere(test);
    refresh();
  }

  @override
  bool remove(Object? element) {
    bool result = _value.remove(element);
    refresh();
    return result;
  }

  @override
  E removeAt(int index) {
    E result = _value.removeAt(index);
    refresh();
    return result;
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _value.retainWhere(test);
    refresh();
  }

  @override
  int get length => value.length;

  @override
  @protected
  ObsList<E> get value {
    RxInterface.proxy?.addListener(subject);
    return _value;
  }

  @override
  set length(int newLength) {
    _value.length = newLength;
    refresh();
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    _value.insertAll(index, iterable);
    refresh();
  }

  @override
  void insert(int index, E element) {
    _value.insert(index, element);
    refresh();
  }

  @override
  Iterable<E> get reversed => value.reversed;

  @override
  Iterable<E> where(bool Function(E) test) {
    return value.where(test);
  }

  @override
  Iterable<T> whereType<T>() {
    return value.whereType<T>();
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    _value.sort(compare);
    refresh();
  }

  @override
  void removeRange(int start, int end) {
    _value.removeRange(start, end);
    refresh();
  }

  @override
  void clear() {
    _value.clear();
    refresh();
  }
}

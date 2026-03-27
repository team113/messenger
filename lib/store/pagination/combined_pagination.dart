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

import 'package:async/async.dart';
import 'package:get/get.dart';

import '/store/pagination.dart';
import '/util/obs/obs.dart';

/// Utility combining [Pagination]s.
class CombinedPagination<T, K> {
  const CombinedPagination(this.paginations);

  /// [Pagination]s this [CombinedPagination] combines.
  final List<CombinedPaginationEntry<T, Object, K>> paginations;

  /// Indicates whether this [CombinedPagination] have next page.
  RxBool get hasNext => paginations.last.p.hasNext;

  /// Indicated whether the [next] page is being fetched.
  RxBool get nextLoading =>
      paginations
          .firstWhereOrNull((e) => e.p.nextLoading.isTrue)
          ?.p
          .nextLoading ??
      RxBool(false);

  /// List of the items fetched from the [paginations].
  List<T> get items => paginations
      .map((e) => e.p.items.values.toList())
      .reduce((value, e) => value..addAll(e));

  /// Returns a [Stream] of changes of the [paginations].
  Stream<MapChangeNotification<K, T>> get changes =>
      StreamGroup.merge(paginations.map((e) => e.p.items.changes));

  /// Disposes this [CombinedPagination].
  void dispose() {
    for (final p in paginations.map((e) => e.p)) {
      p.dispose();
    }
  }

  /// Resets the [paginations] to its initial state.
  Future<void> clear() async {
    for (final p in paginations.map((e) => e.p)) {
      await p.clear();
    }
  }

  /// Fetches the initial page.
  Future<void> around() async {
    for (final p in paginations.map((e) => e.p)) {
      await p.around();
      if (p.hasNext.isTrue) {
        break;
      } else {
        continue;
      }
    }
  }

  /// Fetches the next page.
  Future<void> next() async =>
      paginations.firstWhereOrNull((e) => e.p.hasNext.isTrue)?.p.next();

  /// Adds the provided [item] to the [paginations].
  Future<void> put(
    T item, {
    bool ignoreBounds = false,
    bool store = true,
  }) async {
    for (final p in paginations.where((p) => p.addIf(item)).map((e) => e.p)) {
      await p.put(item, ignoreBounds: ignoreBounds, store: store);
    }
  }

  /// Removes the item with the provided [key].
  Future<void> remove(K key, {bool store = true}) async {
    for (final p in paginations.map((e) => e.p)) {
      await p.remove(key, store: store);
    }
  }
}

/// Single [CombinedPagination] entry.
class CombinedPaginationEntry<T, O extends Object, K> {
  const CombinedPaginationEntry(this.p, {this.addIf = _defaultOnAdd});

  /// [Pagination] itself.
  final Pagination<T, O, K> p;

  /// Callback, indicating whether the provided [T] item should be added to the
  /// [p], or not.
  final bool Function(T) addIf;

  /// Returns `true` always.
  static bool _defaultOnAdd(_) => true;
}

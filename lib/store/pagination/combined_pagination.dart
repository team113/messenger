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

import 'package:async/async.dart';
import 'package:get/get.dart';

import '/store/pagination.dart';
import '/util/obs/obs.dart';

/// Utility combining [Pagination]s.
class CombinedPagination<T, K extends Comparable> {
  CombinedPagination(this.paginations);

  /// [List] of the [Pagination]s this [CombinedPagination] combines.
  List<(bool Function(T), Pagination<T, dynamic, K>)> paginations;

  /// Indicated whether this [CombinedPagination] have next page.
  RxBool get hasNext => paginations.last.$2.hasNext;

  /// Indicated whether the [next] page is being fetched.
  RxBool get nextLoading =>
      paginations
          .firstWhereOrNull((e) => e.$2.nextLoading.isTrue)
          ?.$2
          .nextLoading ??
      RxBool(false);

  /// List of the items fetched from the [paginations].
  List<T> get items => paginations
      .map((e) => e.$2.items.values.toList())
      .reduce((value, e) => value..addAll(e));

  /// Returns a [Stream] of changes of the [paginations].
  Stream<MapChangeNotification<K, T>> get changes =>
      StreamGroup.merge(paginations.map((e) => e.$2.items.changes));

  /// Resets the [paginations] to its initial state.
  Future<void> clear() async {
    for (final Pagination p in paginations.map((e) => e.$2)) {
      await p.clear();
    }
  }

  /// Fetches the initial page.
  FutureOr<void> around() async {
    for (final Pagination p in paginations.map((e) => e.$2)) {
      await p.around();
      if (p.hasNext.isFalse) {
        continue;
      } else {
        break;
      }
    }
  }

  /// Fetches a next page.
  FutureOr<void> next() =>
      paginations.firstWhereOrNull((e) => e.$2.hasNext.isTrue)?.$2.next();

  /// Adds the provided [item] to the [paginations].
  Future<void> put(T item, {bool ignoreBounds = false}) async {
    for (final Pagination p
        in paginations.where((p) => p.$1(item) == true).map((e) => e.$2)) {
      await p.put(item, ignoreBounds: ignoreBounds);
    }
  }

  /// Removes the item with the provided [key].
  Future<void> remove(K key) async {
    for (final Pagination p in paginations.map((e) => e.$2)) {
      await p.remove(key);
    }
  }
}

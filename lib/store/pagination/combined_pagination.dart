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
  const CombinedPagination(this.pagination);

  /// [Pagination]s this [CombinedPagination] combines.
  final List<(bool Function(T), Pagination<T, Object, K>)> pagination;

  /// Indicates whether this [CombinedPagination] have next page.
  RxBool get hasNext => pagination.last.$2.hasNext;

  /// Indicated whether the [next] page is being fetched.
  RxBool get nextLoading =>
      pagination
          .firstWhereOrNull((e) => e.$2.nextLoading.isTrue)
          ?.$2
          .nextLoading ??
      RxBool(false);

  /// List of the items fetched from the [pagination].
  List<T> get items => pagination
      .map((e) => e.$2.items.values.toList())
      .reduce((value, e) => value..addAll(e));

  /// Returns a [Stream] of changes of the [pagination].
  Stream<MapChangeNotification<K, T>> get changes =>
      StreamGroup.merge(pagination.map((e) => e.$2.items.changes));

  /// Resets the [pagination] to its initial state.
  Future<void> clear() async {
    for (final p in pagination.map((e) => e.$2)) {
      await p.clear();
    }
  }

  /// Fetches the initial page.
  FutureOr<void> around() async {
    for (final p in pagination.map((e) => e.$2)) {
      await p.around();
      if (items.isNotEmpty) {
        break;
      } else {
        continue;
      }
    }
  }

  /// Fetches the next page.
  FutureOr<void> next() =>
      pagination.firstWhereOrNull((e) => e.$2.hasNext.isTrue)?.$2.next();

  /// Adds the provided [item] to the [pagination].
  Future<void> put(T item, {bool ignoreBounds = false}) async {
    for (final p in pagination.where((p) => p.$1(item)).map((e) => e.$2)) {
      await p.put(item, ignoreBounds: ignoreBounds);
    }
  }

  /// Removes the item with the provided [key].
  Future<void> remove(K key) async {
    for (final p in pagination.map((e) => e.$2)) {
      await p.remove(key);
    }
  }
}

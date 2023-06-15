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

import 'package:get/get.dart';

import '/util/obs/obs.dart';
import 'model/page_info.dart';

/// [Page]s maintainer utility of the provided [T] values with the specified [K]
/// key identifying those items and their [C] cursor.
class Pagination<T, K, C> {
  Pagination({
    this.perPage = 10,
    required this.provider,
    required this.onKey,
  });

  /// Size of a page to fetch.
  final int perPage;

  /// List of the elements fetched from the [provider].
  final RxSplayTreeMap<K, T> items = RxSplayTreeMap();

  /// [PageProvider] providing the [elements].
  final PageProvider<T, C> provider;

  /// Reactive [RxStatus] of the [items].
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [items] are loaded.
  /// - `status.isLoading`, meaning the [items] are being fetched.
  /// - `status.isLoadingMore`, meaning some [items] were fetched, however
  ///   previous or next items are being fetched additionally.
  /// - `status.isSuccess`, meaning the [items] were successfully fetched.
  final Rx<RxStatus> status = Rx(RxStatus.empty());

  /// Indicator whether the [items] have next page.
  final RxBool hasNext = RxBool(true);

  /// Indicator whether the [items] have previous page.
  final RxBool hasPrevious = RxBool(true);

  /// Callback, called when a key of type [K] identifying the provided [T] item
  /// is required.
  final K Function(T) onKey;

  C? _startCursor;
  C? _endCursor;

  /// Returns stream of record of changes of the [elements].
  Stream<MapChangeNotification<K, T>> get changes => items.changes;

  /// Resets this [Pagination] to its initial state.
  void clear() {
    status.value = RxStatus.empty();
    items.clear();
    hasNext.value = true;
    hasPrevious.value = true;
    _startCursor = null;
    _endCursor = null;
  }

  /// Fetches the [Page] around the provided [item] or [cursor].
  ///
  /// If neither [item] nor [cursor] is provided, then fetches the first [Page].
  Future<void> around({T? item, C? cursor}) async {
    clear();

    status.value = RxStatus.loading();

    final Page<T, C>? page = await provider.around(item, cursor, perPage);

    for (var e in page?.edges ?? []) {
      items[onKey(e)] = e;
    }

    _startCursor = page?.info.startCursor;
    _endCursor = page?.info.endCursor;
    hasNext.value = page?.info.hasNext ?? true;
    hasPrevious.value = page?.info.hasPrevious ?? true;
    status.value = RxStatus.success();
  }

  /// Fetches a next page of the [items].
  FutureOr<void> next() async {
    if (items.isEmpty) {
      return around();
    }

    status.value = RxStatus.loadingMore();

    if (hasNext.value) {
      final Page<T, C>? page =
          await provider.after(items[items.lastKey()], _endCursor, perPage);

      if (page?.info.startCursor != null) {
        for (var e in page?.edges ?? []) {
          items[onKey(e)] = e;
        }
      }

      _endCursor = page?.info.endCursor ?? _endCursor;
      hasNext.value = page?.info.hasNext ?? hasNext.value;
      status.value = RxStatus.success();
    }
  }

  /// Fetches a previous page of the [items].
  FutureOr<void> previous() async {
    if (items.isEmpty) {
      return around();
    }

    status.value = RxStatus.loadingMore();

    if (hasPrevious.value) {
      final Page<T, C>? page =
          await provider.before(items[items.firstKey()], _startCursor, perPage);

      if (page?.info.endCursor != null) {
        for (var e in page?.edges ?? []) {
          items[onKey(e)] = e;
        }
      }

      _startCursor = page?.info.startCursor ?? _startCursor;
      hasPrevious.value = page?.info.hasPrevious ?? hasPrevious.value;
      status.value = RxStatus.success();
    }
  }

  /// Adds the provided [item] to the [items].
  Future<void> put(T item) async {
    items[onKey(item)] = item;
    await provider.add(item);
  }
}

/// List of [T] items along with their [PageInfo] containing the [C] cursor.
class Page<T, C> {
  Page(this.edges, this.info);

  /// Reactive [RxStatus] of the [Page] being fetched.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning the page is not fetched.
  /// - `status.isLoading`, meaning the [edges] are being fetched.
  /// - `status.isLoadingMore`, meaning some [edges] were fetched from local
  ///   storage.
  /// - `status.isSuccess`, meaning the [edges] were successfully fetched.
  final Rx<RxStatus> status = Rx(RxStatus.success());

  /// List of the fetched items.
  final RxList<T> edges;

  /// [PageInfo] of this [Page].
  PageInfo<C> info;
}

/// Base class for fetching items with pagination.
abstract class PageProvider<T, K> {
  /// Fetches the [Page] around the provided [item] or [cursor].
  ///
  /// If neither [item] nor [cursor] is provided, then fetches the first [Page].
  FutureOr<Page<T, K>?> around(T? item, K? cursor, int count);

  /// Fetches the [Page] after the provided [item] or [cursor].
  FutureOr<Page<T, K>?> after(T? item, K? cursor, int count);

  /// Fetches the [Page] before the provided [item] or [cursor].
  FutureOr<Page<T, K>?> before(T? item, K? cursor, int count);

  /// Adds the provided [item] to the [Page] it belongs to.
  Future<void> add(T item);
}

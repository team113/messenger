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

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';
import 'package:messenger/util/log.dart';

import '/util/obs/obs.dart';
import 'model/page_info.dart';

/// [Page]s maintainer utility of the provided [T] values with the specified [K]
/// key identifying those items and their [C] cursor.
class Pagination<T, K extends Comparable, C> {
  Pagination({
    this.perPage = 20,
    required this.provider,
    required this.onKey,
  });

  /// Items per [Page] to fetch.
  final int perPage;

  /// List of the items fetched from the [provider].
  final RxObsSplayTreeMap<K, T> items = RxObsSplayTreeMap();

  /// [PageProvider] providing the [items].
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

  /// Cursor of the first item in the [items] list.
  @visibleForTesting
  C? startCursor;

  /// Cursor of the last item in the [items] list.
  @visibleForTesting
  C? endCursor;

  /// Returns a [Stream] of changes of the [items].
  Stream<MapChangeNotification<K, T>> get changes => items.changes;

  /// Resets this [Pagination] to its initial state.
  void clear() {
    Log.print('clear()', 'Pagination');
    status.value = RxStatus.empty();
    items.clear();
    hasNext.value = true;
    hasPrevious.value = true;
    startCursor = null;
    endCursor = null;
  }

  /// Fetches the [Page] around the provided [item] or [cursor].
  ///
  /// If neither [item] nor [cursor] is provided, then fetches the first [Page].
  Future<void> around({T? item, C? cursor}) async {
    Log.print('around(item: $item, cursor: $cursor)...', 'Pagination');
    clear();

    status.value = RxStatus.loading();

    final Page<T, C>? page = await provider.around(item, cursor, perPage);
    Log.print(
      'around(item: $item, cursor: $cursor)... \n'
          '\tFetched ${page?.edges.length} items\n'
          '\tstartCursor: ${page?.info.startCursor}\n'
          '\tendCursor: ${page?.info.endCursor}\n'
          '\thasPrevious: ${page?.info.hasPrevious}\n'
          '\thasNext: ${page?.info.hasNext}',
      'Pagination',
    );

    for (var e in page?.edges ?? []) {
      items[onKey(e)] = e;
    }

    startCursor = page?.info.startCursor;
    endCursor = page?.info.endCursor;
    hasNext.value = page?.info.hasNext ?? true;
    hasPrevious.value = page?.info.hasPrevious ?? true;
    status.value = RxStatus.success();
    Log.print('around(item: $item, cursor: $cursor)... done', 'Pagination');
  }

  /// Fetches a next page of the [items].
  FutureOr<void> next() async {
    Log.print('next()...', 'Pagination');

    if (items.isEmpty) {
      return around();
    }

    status.value = RxStatus.loadingMore();

    if (hasNext.value) {
      await Future.delayed(const Duration(seconds: 2));
      final Page<T, C>? page =
          await provider.after(items[items.lastKey()], endCursor, perPage);
      Log.print('next()... fetched ${page?.edges.length} items', 'Pagination');

      if (page?.info.startCursor != null) {
        for (var e in page?.edges ?? []) {
          items[onKey(e)] = e;
        }
      }

      endCursor = page?.info.endCursor ?? endCursor;
      hasNext.value = page?.info.hasNext ?? hasNext.value;
      status.value = RxStatus.success();
      Log.print('next()... done', 'Pagination');
    }
  }

  /// Fetches a previous page of the [items].
  FutureOr<void> previous() async {
    Log.print('previous()...', 'Pagination');
    if (items.isEmpty) {
      return around();
    }

    status.value = RxStatus.loadingMore();

    if (hasPrevious.value) {
      await Future.delayed(const Duration(seconds: 2));
      final Page<T, C>? page =
          await provider.before(items[items.firstKey()], startCursor, perPage);
      Log.print(
        'previous()... fetched ${page?.edges.length} items',
        'Pagination',
      );

      if (page?.info.endCursor != null) {
        for (var e in page?.edges ?? []) {
          items[onKey(e)] = e;
        }
      }

      startCursor = page?.info.startCursor ?? startCursor;
      hasPrevious.value = page?.info.hasPrevious ?? hasPrevious.value;
      status.value = RxStatus.success();
      Log.print('previous()... done', 'Pagination');
    }
  }

  /// Adds the provided [item] to the [items].
  ///
  /// [item] will be added if it is within the bounds of the stored [items].
  Future<void> put(T item) async {
    Log.print('put($item)', 'Pagination');
    final K key = onKey(item);

    Future<void> put() async {
      items[onKey(item)] = item;
      await provider.put(item);
    }

    if (items.isEmpty) {
      if (hasNext.isFalse && hasPrevious.isFalse) {
        await put();
      }
    } else if (key.compareTo(items.lastKey()) == 1) {
      if (hasNext.isFalse) {
        await put();
      }
    } else if (key.compareTo(items.firstKey()) == -1) {
      if (hasPrevious.isFalse) {
        await put();
      }
    } else {
      await put();
    }
  }

  /// Removes the item with the provided [key] from the [items].
  void remove(K key) {
    items.remove(key);
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

  Page<T, C> reversed({bool info = true, bool edges = false}) {
    return Page(
      RxList.from(edges ? this.edges.reversed : this.edges),
      info
          ? PageInfo(
              hasNext: this.info.hasPrevious,
              hasPrevious: this.info.hasNext,
              startCursor: this.info.endCursor,
              endCursor: this.info.startCursor,
            )
          : this.info,
    );
  }
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
  Future<void> put(T item);
}

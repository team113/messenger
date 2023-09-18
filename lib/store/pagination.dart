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
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';
import 'package:mutex/mutex.dart';

import '/util/log.dart';
import '/util/obs/obs.dart';
import 'model/page_info.dart';

/// [Page]s maintainer utility of the provided [T] values with the specified [K]
/// key identifying those items and their [C] cursor.
class Pagination<T, C, K extends Comparable> {
  Pagination({
    this.perPage = 50,
    required this.provider,
    required this.onKey,
    this.compare,
  });

  /// Items per [Page] to fetch.
  final int perPage;

  /// List of the items fetched from the [provider].
  final RxObsSplayTreeMap<K, T> items = RxObsSplayTreeMap();

  /// [PageProvider] providing the [items].
  final PageProvider<T, C, K> provider;

  /// Indicator whether the [items] have next page.
  final RxBool hasNext = RxBool(true);

  /// Indicator whether the [items] have previous page.
  final RxBool hasPrevious = RxBool(true);

  /// Indicator whether the [next] page of [items] is being fetched.
  final RxBool nextLoading = RxBool(false);

  /// Indicator whether the [previous] page of [items] is being fetched.
  final RxBool previousLoading = RxBool(false);

  /// Callback, called when a key of type [K] identifying the provided [T] item
  /// is required.
  final K Function(T) onKey;

  /// Callback, comparing the provided [T] items.
  final int Function(T, T)? compare;

  /// Cursor of the first item in the [items] list.
  @visibleForTesting
  C? startCursor;

  /// Cursor of the last item in the [items] list.
  @visibleForTesting
  C? endCursor;

  /// First [T] item in the [items].
  T? firstItem;

  /// Last [T] item in the [items].
  T? lastItem;

  /// [Mutex] guarding synchronized access to the [init] and [around].
  final Mutex _guard = Mutex();

  /// Returns a [Stream] of changes of the [items].
  Stream<MapChangeNotification<K, T>> get changes => items.changes;

  /// Resets this [Pagination] to its initial state.
  Future<void> clear() {
    Log.print('reset()', 'Pagination');
    items.clear();
    hasNext.value = true;
    hasPrevious.value = true;
    startCursor = null;
    endCursor = null;
    return provider.clear();
  }

  /// Fetches the initial [Page] of [items].
  Future<void> init(T? item) {
    return _guard.protect(() async {
      final Page<T, C>? page = await provider.init(item, perPage);
      Log.print(
        'init(item: $item)... \n'
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
      firstItem = page?.edges.firstOrNull ?? firstItem;
      lastItem = page?.edges.lastOrNull ?? lastItem;
      hasNext.value = page?.info.hasNext ?? hasNext.value;
      hasPrevious.value = page?.info.hasPrevious ?? hasPrevious.value;
      Log.print('init(item: $item)... done', 'Pagination');
    });
  }

  /// Fetches the [Page] around the provided [item] or [cursor].
  ///
  /// If neither [item] nor [cursor] is provided, then fetches the first [Page].
  Future<void> around({T? item, C? cursor}) {
    return _guard.protect(() async {
      Log.print('around(item: $item, cursor: $cursor)...', 'Pagination');

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
      firstItem = page?.edges.firstOrNull ?? firstItem;
      lastItem = page?.edges.lastOrNull ?? firstItem;
      hasNext.value = page?.info.hasNext ?? hasNext.value;
      hasPrevious.value = page?.info.hasPrevious ?? hasPrevious.value;
      Log.print('around(item: $item, cursor: $cursor)... done', 'Pagination');
    });
  }

  /// Fetches a next page of the [items].
  FutureOr<void> next() async {
    Log.print('next()...', 'Pagination');

    if (hasNext.isTrue && nextLoading.isFalse) {
      nextLoading.value = true;

      if (items.isNotEmpty) {
        final Page<T, C>? page;
        if (compare != null) {
          page = await provider.after(lastItem, endCursor, perPage);
        } else {
          page =
              await provider.after(items[items.lastKey()], endCursor, perPage);
        }

        Log.print(
          'next()... fetched ${page?.edges.length} items',
          'Pagination',
        );

        for (var e in page?.edges ?? []) {
          items[onKey(e)] = e;
        }

        endCursor = page?.info.endCursor ?? endCursor;
        lastItem = page?.edges.lastOrNull ?? lastItem;
        hasNext.value = page?.info.hasNext ?? hasNext.value;
        Log.print('next()... done', 'Pagination');
      } else {
        await around();
      }

      nextLoading.value = false;
    }
  }

  /// Fetches a previous page of the [items].
  FutureOr<void> previous() async {
    Log.print('previous()...', 'Pagination');
    if (items.isEmpty) {
      return around();
    }

    if (hasPrevious.isTrue && previousLoading.isFalse) {
      previousLoading.value = true;

      final Page<T, C>? page;
      if (compare != null) {
        page = await provider.before(firstItem, startCursor, perPage);
      } else {
        page = await provider.before(
          items[items.firstKey()],
          startCursor,
          perPage,
        );
      }
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
      firstItem = page?.edges.firstOrNull ?? firstItem;
      hasPrevious.value = page?.info.hasPrevious ?? hasPrevious.value;
      Log.print('previous()... done', 'Pagination');

      previousLoading.value = false;
    }
  }

  /// Adds the provided [item] to the [items].
  ///
  /// [item] will be added if it is within the bounds of the stored [items].
  Future<void> put(T item, {bool ignoreBounds = false}) async {
    Log.print('put($item)', 'Pagination');

    Future<void> put() async {
      K key = onKey(item);

      items[key] = item;

      if (compare != null) {
        if (firstItem != null && key == onKey(firstItem as T)) {
          firstItem = items.values.sorted(compare!).first;
        }

        if (lastItem != null && key == onKey(lastItem as T)) {
          lastItem = items.values.sorted(compare!).last;
        }
      }

      await provider.put(item);
    }

    if (ignoreBounds) {
      await put();
      return;
    }

    if (items.isEmpty) {
      if (hasNext.isFalse && hasPrevious.isFalse) {
        await put();
      }
      return;
    }

    if (compare != null) {
      if (compare!.call(item, lastItem as T) == 1) {
        if (hasNext.isFalse) {
          await put();
        }
      } else if (compare!.call(item, firstItem as T) == -1) {
        if (hasPrevious.isFalse) {
          await put();
        }
      } else {
        await put();
      }
    } else {
      final K key = onKey(item);

      if (key.compareTo(items.lastKey()) == 1) {
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
  }

  /// Removes the item with the provided [key] from the [items] and [provider].
  Future<void> remove(K key) {
    items.remove(key);

    if (compare != null) {
      if (firstItem != null && key == onKey(firstItem as T)) {
        firstItem = items.values.sorted(compare!).first;
      }

      if (lastItem != null && key == onKey(lastItem as T)) {
        lastItem = items.values.sorted(compare!).last;
      }
    }

    return provider.remove(key);
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

  /// Returns a new [Page] with reversed [info].
  Page<T, C> reversed() {
    return Page(
      RxList.from(this.edges.reversed),
      PageInfo(
        hasNext: this.info.hasPrevious,
        hasPrevious: this.info.hasNext,
        startCursor: this.info.endCursor,
        endCursor: this.info.startCursor,
      ),
    );
  }
}

/// Utility providing the [Page]s.
abstract class PageProvider<T, C, K> {
  /// Initializes this [PageProvider], loading initial [Page], if any.
  Future<Page<T, C>?> init(T? item, int count);

  /// Fetches the [Page] around the provided [item] or [cursor].
  ///
  /// If neither [item] nor [cursor] is provided, then fetches the first [Page].
  FutureOr<Page<T, C>?> around(T? item, C? cursor, int count);

  /// Fetches the [Page] after the provided [item] or [cursor].
  FutureOr<Page<T, C>?> after(T? item, C? cursor, int count);

  /// Fetches the [Page] before the provided [item] or [cursor].
  FutureOr<Page<T, C>?> before(T? item, C? cursor, int count);

  /// Adds the provided [item] to this [PageProvider].
  Future<void> put(T item);

  /// Removes the item specified by its [key] from this [PageProvider].
  Future<void> remove(K key);

  /// Clears this [PageProvider].
  Future<void> clear();
}

/// [PageProvider] page fetching strategy.
enum PaginationStrategy {
  /// [Page]s fetching starts from the beginning of the available window.
  fromStart,

  /// [Page]s fetching starts from the end of the available window.
  fromEnd,
}

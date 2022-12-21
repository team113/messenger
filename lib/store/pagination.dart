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

import '/api/backend/schema.dart' show PageInfoMixin;
import '/store/chat_rx.dart';
import '/util/obs/rxlist.dart';

class PaginatedFragment<T> {
  PaginatedFragment({
    this.pageSize = 120,
    this.initialCursor,
    required this.compare,
    required this.equal,
    required this.cache,
    required this.onFetchPage,
    this.ignore,
  });

  final int pageSize;

  final String? initialCursor;

  final int Function(T a, T b) compare;

  final bool Function(T a, T b) equal;

  final List<T> cache;

  final List<T> _synced = [];

  final Future<ItemsPage<T>?> Function({
    int? first,
    String? after,
    int? last,
    String? before,
  }) onFetchPage;

  final bool Function(T)? ignore;

  final RxObsList<T> elements = RxObsList<T>();

  bool isPrevPageLoading = false;

  bool isNextPageLoading = false;

  bool hasNextPage = true;

  bool hasPreviousPage = true;

  String? lastItemCursor;

  String? firstItemCursor;

  /// Gets initial elements from the [cache].
  void init() {
    if (initialCursor != null) {
      elements.addAll(cache.take(pageSize ~/ 2));
    } else {
      elements.addAll(cache.take(pageSize));
    }
  }

  Future<void> loadInitialPage() async {
    print('loadInitialPage');
    if (initialCursor != null) {
      ItemsPage<T>? fetched = await onFetchPage(
        first: pageSize ~/ 2 - 1,
        after: initialCursor,
        last: pageSize ~/ 2 - 1,
        before: initialCursor,
      );

      if (fetched == null) {
        return;
      }

      hasNextPage = fetched.pageInfo.hasNextPage;
      hasPreviousPage = fetched.pageInfo.hasPreviousPage;
      lastItemCursor = fetched.pageInfo.endCursor;
      firstItemCursor = fetched.pageInfo.startCursor;

      syncItems(
        fetched.items,
        List<T>.from(elements),
      );

      for (T i in fetched.items) {
        _synced.insertAfter(i, (e) => compare(i, e) == 1);
        if (!elements.replace(i, equal)) {
          elements.insertAfter(i, (e) => compare(i, e) == 1);
        }
      }
    } else {
      hasPreviousPage = false;
      loadNextPage();
    }
  }

  /// Loads next page of the [elements].
  Future<void> loadNextPage() async {
    if (!hasNextPage) {
      return;
    }

    if (cache.length > elements.length) {
      Iterable<T> cached = cache.skip(elements.length).take(pageSize);
      for (T i in cached) {
        elements.insertAfter(i, (e) => compare(i, e) == 1);
      }
    }

    if (!isNextPageLoading) {
      print('loadNextPage start');
      isNextPageLoading = true;

      ItemsPage<T>? fetched = await onFetchPage(
        first: pageSize,
        after: firstItemCursor,
      );
      print(lastItemCursor);

      if (fetched == null) {
        return;
      }

      hasNextPage = fetched.pageInfo.hasNextPage;
      firstItemCursor = fetched.pageInfo.endCursor;

      Iterable<T> cache =
          elements.skip(_synced.length).take(pageSize).map((e) => e);

      syncItems(fetched.items, cache);

      for (T i in fetched.items) {
        _synced.insertAfter(i, (e) => compare(i, e) == 1);
        if (!elements.replace(i, equal)) {
          elements.insertAfter(i, (e) => compare(i, e) == 1);
        }
      }

      if (_synced.length < elements.length) {
        isNextPageLoading = false;
        await loadNextPage();
        print('loadNextPage end');
      }

      isNextPageLoading = false;
    }
  }

  /// Loads previous page of the [elements].
  Future<void> loadPreviousPage() async {
    if (isPrevPageLoading || !hasPreviousPage) {
      return;
    }

    isPrevPageLoading = true;

    ItemsPage<T>? fetched =
        await onFetchPage(last: pageSize, before: lastItemCursor);

    if (fetched == null) {
      return;
    }

    hasPreviousPage = fetched.pageInfo.hasPreviousPage;
    lastItemCursor = fetched.pageInfo.startCursor;

    for (T i in fetched.items) {
      _synced.insertAfter(i, (e) => compare(i, e) == 1);
      cache.insertAfter(i, (e) => compare(i, e) == 1);
      if (!elements.replace(i, equal)) {
        elements.insertAfter(i, (e) => compare(i, e) == 1);
      }
    }

    isPrevPageLoading = false;
  }

  void syncItems(
    List<T> main,
    Iterable<T> secondary,
  ) {
    if (main.isEmpty || secondary.isEmpty) {
      return;
    }

    for (T i in secondary) {
      if (ignore?.call(i) == true) {
        _synced.insertAfter(i, (e) => compare(i, e) == 1);
      } else {
        if (main.indexWhere((e) => equal(i, e)) == -1) {
          if (compare(i, main.last) != -1) {
            // TODO: remove
            cache.remove(i);
            elements.remove(i);
            print('remove1');
          } else {
            elements.remove(i);
            print('remove2');
          }
        }
      }
    }
  }
}

/// An
abstract class ItemsPage<T> {
  List<T> get items;

  PageInfoMixin get pageInfo;
}

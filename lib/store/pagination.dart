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
import 'package:messenger/provider/hive/chat_item.dart';

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
    required this.onDelete,
    this.ignore,
  });

  /// Page size of this [PaginatedFragment].
  final int pageSize;

  /// Initial cursor of this [PaginatedFragment].
  final String? initialCursor;

  /// Callback, called to compare items.
  final int Function(T a, T b) compare;

  /// Indicated whether items are equal.
  final bool Function(T a, T b) equal;

  /// Callback, called to fetch new page.
  final Future<ItemsPage<T>?> Function({
    int? first,
    String? after,
    int? last,
    String? before,
  }) onFetchPage;

  /// Callback, called when an item deleted from the [cache].
  final void Function(T item) onDelete;

  /// [List] of the cached items.
  final List<T> cache;

  /// Indicated whether item should not be deleted from the [cache].
  final bool Function(T)? ignore;

  final RxObsList<T> elements = RxObsList<T>();

  final List<T> _synced = [];

  /// Indicator whether next page is loading.
  bool _isNextPageLoading = false;

  /// Indicator whether previous page is loading.
  bool _isPrevPageLoading = false;

  /// Indicator whether next page is exist.
  bool _hasNextPage = true;

  /// Indicator whether previous page is exist.
  bool _hasPreviousPage = true;

  /// Cursor of the last element in the [_synced].
  String? _lastItemCursor;

  /// Cursor of the first element in the [_synced].
  String? _firstItemCursor;

  /// Gets initial elements page from the [cache].
  void init() {
    if (initialCursor != null) {
      elements.addAll(cache.take(pageSize ~/ 2));
    } else {
      elements.addAll(cache.take(pageSize));
    }
  }

  /// Loads the initial page ot the [elements].
  Future<void> loadInitialPage() async {
    ItemsPage<T>? fetched;
    if (initialCursor != null) {
      fetched = await onFetchPage(
        first: pageSize ~/ 2 - 1,
        after: initialCursor,
        last: pageSize ~/ 2 - 1,
        before: initialCursor,
      );
    } else {
      fetched = await onFetchPage(first: pageSize);
    }

    if (fetched == null) {
      return;
    }

    _hasNextPage = fetched.pageInfo.hasNextPage;
    _hasPreviousPage = fetched.pageInfo.hasPreviousPage;
    _lastItemCursor = fetched.pageInfo.startCursor;
    _firstItemCursor = fetched.pageInfo.endCursor;

    syncItems(
      fetched.items,
      List<T>.from(elements),
    );

    print(fetched.items.length);

    for (T i in fetched.items) {
      _synced.insertAfter(i, (e) => compare(i, e) == 1);
      if (elements.none((e) => equal(e, i))) {
        elements.insertAfter(i, (e) => compare(i, e) == 1);
      }
      if (cache.none((e) => equal(e, i))) {
        cache.insertAfter(i, (e) => compare(i, e) == 1);
      }
    }
  }

  /// Count of the pages loaded from the [cache] and not sync.
  int _overloadedPageCount = 0;

  /// Loads next page of the [elements].
  FutureOr<void> loadNextPage() async {
    if (!_hasNextPage) {
      return;
    }

    if (cache.length > elements.length) {
      Iterable<T> cached = cache.skip(elements.length).take(pageSize);
      for (T i in cached) {
        elements.insertAfter(i, (e) => compare(i, e) == 1);
      }
    }

    if (!_isNextPageLoading) {
      print('loadNextPage start');
      _isNextPageLoading = true;

      ItemsPage<T>? fetched = await onFetchPage(
        first: pageSize,
        after: _firstItemCursor,
      );

      if (fetched == null) {
        return;
      }

      _hasNextPage = fetched.pageInfo.hasNextPage;
      _firstItemCursor = fetched.pageInfo.endCursor;

      List<T> cached =
          cache.skip(_synced.length).take(pageSize).map((e) => e).toList();

      syncItems(fetched.items, cached);

      for (T i in fetched.items) {
        _synced.insertAfter(i, (e) => compare(i, e) == 1);
        if (elements.none((e) => equal(e, i))) {
          elements.insertAfter(i, (e) => compare(i, e) == 1);
        }
        if (cache.none((e) => equal(e, i))) {
          cache.insertAfter(i, (e) => compare(i, e) == 1);
        }
      }

      if (_synced.length < elements.length) {
        _isNextPageLoading = false;
        await loadNextPage();
      }

      _isNextPageLoading = false;
    }
  }

  /// Loads previous page of the [elements].
  FutureOr<void> loadPreviousPage() async {
    if (_isPrevPageLoading || !_hasPreviousPage) {
      return;
    }

    _isPrevPageLoading = true;

    ItemsPage<T>? fetched =
        await onFetchPage(last: pageSize, before: _lastItemCursor);

    if (fetched == null) {
      return;
    }

    _hasPreviousPage = fetched.pageInfo.hasPreviousPage;
    _lastItemCursor = fetched.pageInfo.startCursor;

    for (T i in fetched.items) {
      _synced.insertAfter(i, (e) => compare(i, e) == 1);
      cache.insertAfter(i, (e) => compare(i, e) == 1);
      if (!elements.replace(i, equal)) {
        elements.insertAfter(i, (e) => compare(i, e) == 1);
      }
    }

    _isPrevPageLoading = false;
  }

  void syncItems(
    List<T> main,
    List<T> secondary,
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
            onDelete(i);
            cache.remove(i);
            elements.remove(i);
            print('remove1');
          } else {
            //elements.remove(i);
            print('remove2');
          }
        }
      }
    }
  }
}

/// Page loading result.
abstract class ItemsPage<T> {
  List<T> get items;

  PageInfoMixin get pageInfo;
}

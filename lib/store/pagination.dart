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
import 'package:get/get.dart';

import '/api/backend/schema.dart' show PageInfoMixin;
import '/store/chat_rx.dart';
import '/util/obs/rxlist.dart';

/// Helper to uploads items with pagination.
class PaginatedFragment<T> {
  PaginatedFragment({
    this.pageSize = 30,
    this.initialCursor,
    required this.compare,
    required this.equal,
    this.cache = const [],
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

  /// Callback, called to fetch elements page.
  final Future<ItemsPage<T>?> Function({
    int? first,
    String? after,
    int? last,
    String? before,
  }) onFetchPage;

  /// Callback, called when an item deleted from the [cache].
  final void Function(T item) onDelete;

  /// [List] of the cached items.
  List<T> cache;

  /// Indicated whether item should not be deleted from the [cache] if not
  /// exists on the remote.
  final bool Function(T)? ignore;

  /// List of the elements fetched from [cache] and remote.
  final RxObsList<T> elements = RxObsList<T>();

  /// Elements synchronized with the remote.
  final List<T> _synced = [];

  /// Indicator whether next page is loading.
  bool _isNextPageLoading = false;

  /// Indicator whether previous page is loading.
  bool _isPrevPageLoading = false;

  /// Indicator whether next page is exist.
  final RxBool _hasNextPage = RxBool(false);

  /// Indicator whether previous page is exist.
  final RxBool _hasPreviousPage = RxBool(false);

  /// Cursor of the last element in the [_synced].
  String? _firstItemCursor;

  /// Cursor of the first element in the [_synced].
  String? _lastItemCursor;

  /// Indicates whether next page is exist.
  RxBool get hasNextPage => _hasNextPage;

  /// Indicates whether previous page is exist.
  RxBool get hasPreviousPage => _hasPreviousPage;

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

    await Future.delayed(const Duration(seconds: 2));
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

    _hasNextPage.value = fetched.pageInfo.hasNextPage;
    _hasPreviousPage.value = fetched.pageInfo.hasPreviousPage;
    _firstItemCursor = fetched.pageInfo.startCursor;
    _lastItemCursor = fetched.pageInfo.endCursor;

    syncItems(fetched.items);

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

  /// Loads next page of the [elements].
  Future<void> loadNextPage({
    Future<void> Function(List<T>)? onItemsLoaded,
  }) async {
    if (_hasNextPage.isFalse) {
      return;
    }

    if (cache.length > elements.length) {
      Future.sync(() async {
        Iterable<T> cached = cache.skip(elements.length).take(pageSize);
        await onItemsLoaded?.call(cached.toList());
        for (T i in cached) {
          elements.insertAfter(i, (e) => compare(i, e) == 1);
        }
      });
    }

    await _loadNextPage(onItemsLoaded: onItemsLoaded);
  }

  /// Loads next page of the [elements].
  Future<void> _loadNextPage({
    Future<void> Function(List<T>)? onItemsLoaded,
  }) async {
    if (!_isNextPageLoading) {
      _isNextPageLoading = true;

      await Future.delayed(const Duration(seconds: 2));

      ItemsPage<T>? fetched = await onFetchPage(
        first: pageSize,
        after: _lastItemCursor,
      );

      if (fetched != null) {
        _hasNextPage.value = fetched.pageInfo.hasNextPage;
        _lastItemCursor = fetched.pageInfo.endCursor;

        syncItems(fetched.items);

        await onItemsLoaded?.call(fetched.items);

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
          await _loadNextPage(onItemsLoaded: onItemsLoaded);
        }
      }

      _isNextPageLoading = false;
    }
  }

  /// Loads previous page of the [elements].
  FutureOr<void> loadPreviousPage() async {
    if (_isPrevPageLoading || _hasPreviousPage.isFalse) {
      return;
    }

    _isPrevPageLoading = true;

    await Future.delayed(const Duration(seconds: 2));
    ItemsPage<T>? fetched =
        await onFetchPage(last: pageSize, before: _firstItemCursor);

    if (fetched != null) {
      _hasPreviousPage.value = fetched.pageInfo.hasPreviousPage;
      _firstItemCursor = fetched.pageInfo.startCursor;

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

    _isPrevPageLoading = false;
  }

  /// Synchronizes the provided [fetched] elements with the [cache].
  void syncItems(List<T> fetched) {
    List<T> secondary =
        cache.skip(_synced.length).take(pageSize).map((e) => e).toList();

    if (fetched.isEmpty || secondary.isEmpty) {
      return;
    }

    for (T i in secondary) {
      if (ignore?.call(i) == true) {
        _synced.insertAfter(i, (e) => compare(i, e) == 1);
      } else {
        if (fetched.indexWhere((e) => equal(i, e)) == -1) {
          if (compare(i, fetched.last) != -1) {
            onDelete(i);
            cache.remove(i);
            elements.remove(i);
          } else {
            elements.remove(i);
          }
        }
      }
    }
  }
}

/// Page loading result.
abstract class ItemsPage<T> {
  /// Loaded items.
  List<T> get items;

  /// Page info of this [ItemsPage].
  PageInfoMixin get pageInfo;
}

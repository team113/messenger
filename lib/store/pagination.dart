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

/// Helper to fetches items with pagination.
class PaginatedFragment<T> {
  PaginatedFragment({
    this.pageSize = 10,
    this.initialCursor,
    required this.compare,
    required this.equal,
    this.cache = const [],
    required this.onFetchPage,
    required this.onDelete,
    this.ignore,
  });

  /// Size of a page to fetch.
  final int pageSize;

  /// Cursor to fetch initial items around.
  final String? initialCursor;

  /// Callback, called to compare items.
  final int Function(T a, T b) compare;

  /// Indicated whether items are equal.
  final bool Function(T a, T b) equal;

  /// Callback, called to fetch items page.
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

  /// Indicates whether item should not be deleted from the [cache] if not
  /// exists on the remote.
  final bool Function(T)? ignore;

  /// List of the elements fetched from [cache] and remote.
  final RxObsList<T> elements = RxObsList<T>();

  /// Indicator whether next page is exist.
  final RxBool hasNextPage = RxBool(false);

  /// Indicator whether previous page is exist.
  final RxBool hasPreviousPage = RxBool(false);

  /// Elements uploaded from the remote.
  final List<T> _synced = [];

  /// Indicator whether next page is loading.
  bool _isNextPageLoading = false;

  /// Indicator whether previous page is loading.
  bool _isPrevPageLoading = false;

  /// Cursor to fetch the previous page.
  String? _startCursor;

  /// Cursor to fetch the next page.
  String? _endCursor;

  /// Gets initial page from the [cache].
  void init() {
    if (initialCursor != null) {
      elements.addAll(cache.take(pageSize ~/ 2));
    } else {
      elements.addAll(cache.take(pageSize));
    }
  }

  /// Fetches the initial page from the remote.
  Future<void> loadInitialPage() async {
    if (_synced.isNotEmpty) {
      // Return if initial page is already fetched.
      return;
    }

    // TODO: Temporary timeout, remove before merging.
    await Future.delayed(const Duration(seconds: 2));

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

    if (fetched != null) {
      hasNextPage.value = fetched.pageInfo.hasNextPage;
      hasPreviousPage.value = fetched.pageInfo.hasPreviousPage;
      _startCursor = fetched.pageInfo.startCursor;
      _endCursor = fetched.pageInfo.endCursor;

      _syncItems(fetched.items);

      for (T i in fetched.items) {
        _add(i);
      }
    }
  }

  /// Fetches next page of the [elements].
  Future<void> loadNextPage() async {
    if (hasNextPage.isFalse) {
      return;
    }

    if (cache.length > elements.length) {
      Future.sync(() async {
        Iterable<T> cached = cache.skip(elements.length).take(pageSize);
        for (T i in cached) {
          elements.insertAfter(i, (e) => compare(i, e) == 1);
        }
      });
    }

    await _loadNextPage();
  }

  /// Fetches next page of the [elements].
  Future<void> _loadNextPage({
    Future<void> Function(List<T>)? onItemsLoaded,
  }) async {
    if (!_isNextPageLoading) {
      _isNextPageLoading = true;

      // TODO: Temporary timeout, remove before merging.
      await Future.delayed(const Duration(seconds: 2));

      ItemsPage<T>? fetched = await onFetchPage(
        first: pageSize,
        after: _endCursor,
      );

      if (fetched != null) {
        hasNextPage.value = fetched.pageInfo.hasNextPage;
        _endCursor = fetched.pageInfo.endCursor;

        _syncItems(fetched.items);

        await onItemsLoaded?.call(fetched.items);

        for (T i in fetched.items) {
          _add(i);
        }

        if (_synced.length < elements.length) {
          _isNextPageLoading = false;
          await _loadNextPage(onItemsLoaded: onItemsLoaded);
        }
      }

      _isNextPageLoading = false;
    }
  }

  /// Fetches previous page of the [elements].
  FutureOr<void> loadPreviousPage() async {
    if (_isPrevPageLoading || hasPreviousPage.isFalse) {
      return;
    }

    _isPrevPageLoading = true;

    // TODO: Temporary timeout, remove before merging.
    await Future.delayed(const Duration(seconds: 2));

    ItemsPage<T>? fetched =
        await onFetchPage(last: pageSize, before: _startCursor);

    if (fetched != null) {
      hasPreviousPage.value = fetched.pageInfo.hasPreviousPage;
      _startCursor = fetched.pageInfo.startCursor;

      for (T i in fetched.items) {
        _add(i);
      }
    }

    _isPrevPageLoading = false;
  }

  /// Inserts the provided [item] to the [_synced], [elements] and [cache].
  void _add(T item) {
    _synced.insertAfter(item, (e) => compare(item, e) == 1);

    final int i = elements.indexWhere((e) => equal(e, item));
    if (i == -1) {
      elements.insertAfter(item, (e) => compare(item, e) == 1);
    } else {
      elements[i] = item;
    }

    if (cache.none((e) => equal(e, item))) {
      cache.insertAfter(item, (e) => compare(item, e) == 1);
    }
  }

  /// Synchronizes the provided [fetched] elements with the [cache].
  void _syncItems(List<T> fetched) {
    List<T> secondary =
        cache.skip(_synced.length).take(fetched.length).map((e) => e).toList();

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

/// Page fetching result.
abstract class ItemsPage<T> {
  /// Fetched items.
  List<T> get items;

  /// Page info of this [ItemsPage].
  PageInfoMixin get pageInfo;
}

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

import '/store/chat_rx.dart';
import '/util/obs/rxlist.dart';
import 'model/page_info.dart';

/// [Page]s maintainer utility of the provided [T] values with the specified [K]
/// cursor identifying those items.
class Pagination<T, K> {
  Pagination({
    this.perPage = 10,
    required this.provider,
    required this.compare,
  });

  /// Size of a page to fetch.
  final int perPage;

  /// List of the elements fetched from the [provider].
  final RxObsList<T> elements = RxObsList();

  /// [PageProvider] providing the [elements].
  final PageProvider<T, K> provider;

  /// Indicator whether [elements] has next page.
  final RxBool hasNext = RxBool(true);

  /// Indicator whether [elements] has previous page.
  final RxBool hasPrevious = RxBool(true);

  /// Callback, called to compare items.
  final int Function(T a, T b) compare;

  /// Cursor pointing the first item in the [elements].
  K? _startCursor;

  /// Cursor pointing the last item in the [elements].
  K? _endCursor;

  /// [List] of the [StreamSubscription] for the [Page.edges].
  List<StreamSubscription> pageSubscriptions = [];

  /// Resets this [Pagination] to its initial state.
  void clear() {
    elements.clear();
    hasNext.value = true;
    hasPrevious.value = true;
    _startCursor = null;
    _endCursor = null;
    for (var e in pageSubscriptions) {
      e.cancel();
    }
    pageSubscriptions.clear();
  }

  /// Disposes this [Pagination].
  void dispose() {
    for (var e in pageSubscriptions) {
      e.cancel();
    }
    pageSubscriptions.clear();
  }

  /// Fetches the [Page] around the provided [item] or [cursor].
  ///
  /// If neither [item] nor [cursor] is provided, then fetches the first [Page].
  FutureOr<void> around({T? item, K? cursor}) async {
    clear();

    final Rx<Page<T, K>> page = await provider.around(item, cursor, perPage);

    PageInfo<K>? storedInfo = page.value.info;
    StreamSubscription? subscription;
    subscription = page.listen((page) {
      for (var e in page.edges) {
        _add(e);
      }

      if (_startCursor == storedInfo?.startCursor) {
        _startCursor = page.info?.startCursor;
      }
      if (_endCursor == storedInfo?.endCursor) {
        _endCursor = page.info?.endCursor;
      }

      subscription?.cancel();
      pageSubscriptions.remove(subscription);
    });
    pageSubscriptions.add(subscription);

    if (page.value.info != null) {
      for (var e in page.value.edges) {
        _add(e);
      }
      hasNext.value = page.value.info!.hasNext;
      hasPrevious.value = page.value.info!.hasPrevious;
      _startCursor = page.value.info!.startCursor;
      _endCursor = page.value.info!.endCursor;
    } else {
      hasNext.value = false;
      hasPrevious.value = false;
    }
  }

  /// Fetches a next page of the [elements].
  FutureOr<void> next() async {
    if (elements.isEmpty) {
      return around();
    }

    if (hasNext.isTrue) {
      final Page<T, K>? page =
          await provider.after(elements.last, _endCursor, perPage);
      if (page != null) {
        for (var e in page.edges) {
          _add(e);
        }
        hasNext.value = page.info!.hasNext;
        _endCursor = page.info!.endCursor ?? _endCursor;

        if (page.edges.length < perPage) {
          // load next or prev page??
          // may be jumps in chat
        }
      } else {
        hasNext.value = false;
      }
    }
  }

  /// Fetches a previous page of the [elements].
  FutureOr<void> previous() async {
    if (elements.isEmpty) {
      return around();
    }

    if (hasPrevious.isTrue) {
      final Page<T, K>? page =
          await provider.before(elements.first, _startCursor, perPage);
      if (page != null) {
        for (var e in page.edges) {
          _add(e);
        }
        hasPrevious.value = page.info!.hasPrevious;
        _startCursor = page.info!.startCursor ?? _startCursor;
      } else {
        hasPrevious.value = false;
      }
    }
  }

  /// Adds the provided [item] to the [elements].
  void add(T item) {
    if (elements.isNotEmpty) {
      if ((compare(item, elements.first) == 1 || hasPrevious.isFalse) &&
          (compare(item, elements.last) == -1 || hasNext.isFalse)) {
        _add(item);
      }
    } else if (hasNext.isFalse && hasPrevious.isFalse) {
      _add(item);
    }
  }

  /// Adds the provided [item] to the [elements].
  void _add(T item) {
    int i = elements.indexWhere((e) => e == item);
    if (i == -1) {
      elements.insertAfter(item, (e) => compare(item, e) == 1);
    } else {
      elements[i] = item;
    }
  }
}

/// Result of a paginated page fetching.
class Page<T, K> {
  Page(this.edges, [this.info]);

  /// List of the fetched items.
  List<T> edges;

  /// [PageInfo] of this [Page].
  PageInfo<K>? info;
}

/// Base class for load items with pagination.
abstract class PageProvider<T, K> {
  /// Gets items page around the provided [item] or [cursor].
  FutureOr<Rx<Page<T, K>>> around(T? item, K? cursor, int count);

  /// Gets items page after the provided [item] or [cursor].
  FutureOr<Page<T, K>?> after(T? item, K? cursor, int count);

  /// Gets items page before the provided [item] or [cursor].
  FutureOr<Page<T, K>?> before(T? item, K? cursor, int count);
}

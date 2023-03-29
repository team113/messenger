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
    required this.sameItems,
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

  /// Indicator whether [around] elements was fetched.
  final RxBool aroundFetched = RxBool(false);

  /// Callback, called to compare items.
  final int Function(T a, T b) compare;

  /// Callback, called to compare items.
  final bool Function(T a, T b) sameItems;

  /// Cursor pointing the first item in the [elements].
  K? _startCursor;

  /// Cursor pointing the last item in the [elements].
  K? _endCursor;

  /// [StreamSubscription] for the [Page] fetched in the [around].
  StreamSubscription? _aroundSubscription;

  /// Disposes this [Pagination].
  void dispose() {
    _aroundSubscription?.cancel();
  }

  /// Resets this [Pagination] to its initial state.
  void clear() {
    elements.clear();
    hasNext.value = true;
    hasPrevious.value = true;
    _startCursor = null;
    _endCursor = null;
    _aroundSubscription?.cancel();
    aroundFetched.value = false;
  }

  /// Fetches the [Page] around the provided [item] or [cursor].
  ///
  /// If neither [item] nor [cursor] is provided, then fetches the first [Page].
  Future<void> around({T? item, K? cursor}) async {
    clear();

    final Rx<Page<T, K>> page = await provider.around(item, cursor, perPage);

    if (!page.value.finalResult) {
      PageInfo<K>? storedInfo = page.value.info;
      _aroundSubscription?.cancel();
      _aroundSubscription = page.listen((p) {
        for (var e in p.edges) {
          _add(e);
        }

        if (_startCursor == storedInfo?.startCursor) {
          _startCursor = p.info?.startCursor;
        }
        if (_endCursor == storedInfo?.endCursor) {
          _endCursor = p.info?.endCursor;
        }

        hasNext.value = p.info!.hasNext;
        hasPrevious.value = p.info!.hasPrevious;

        _aroundSubscription?.cancel();
        aroundFetched.value = true;
      });
    } else {
      aroundFetched.value = true;
    }

    if (page.value.info != null) {
      for (var e in page.value.edges) {
        _add(e);
      }
      hasNext.value = page.value.info!.hasNext;
      hasPrevious.value = page.value.info!.hasPrevious;
      _startCursor = page.value.info!.startCursor;
      _endCursor = page.value.info!.endCursor;
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
      }
    }
  }

  /// Adds the provided [item] to the [elements].
  ///
  /// [item] will be added if it is within the bounds of the stored [elements].
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
    int i = elements.indexWhere((e) => sameItems(e, item));
    if (i == -1) {
      elements.insertAfter(item, (e) => compare(item, e) == 1);
    } else {
      elements[i] = item;
    }
  }
}

/// Result of a paginated page fetching.
class Page<T, K> {
  Page(this.edges, {this.info, this.finalResult = true});

  /// List of the fetched items.
  List<T> edges;

  /// [PageInfo] of this [Page].
  PageInfo<K>? info;

  /// Indicator whether this [Page] will not be updated.
  bool finalResult;
}

/// Base class for fetching items with pagination.
abstract class PageProvider<T, K> {
  /// Fetches the [Page] around the provided [item] or [cursor].
  ///
  /// If neither [item] nor [cursor] is provided, then fetches the first [Page].
  FutureOr<Rx<Page<T, K>>> around(T? item, K? cursor, int count);

  /// Fetches the [Page] after the provided [item] or [cursor].
  FutureOr<Page<T, K>?> after(T? item, K? cursor, int count);

  /// Fetches the [Page] before the provided [item] or [cursor].
  FutureOr<Page<T, K>?> before(T? item, K? cursor, int count);
}

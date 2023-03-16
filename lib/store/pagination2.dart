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

import 'model/page_info.dart';

/// [Page]s maintainer utility of the provided [T] values with the specified [K]
/// cursor identifying those items.
class Pagination<T, K> {
  Pagination({
    this.perPage = 10,
    required this.provider,
  });

  final int perPage;

  final RxList<Page<T, K>> pages = RxList();

  /// [PageProvider] providing the [pages].
  final PageProvider<T, K> provider;

  final RxBool hasNext = RxBool(true);
  final RxBool hasPrevious = RxBool(true);

  /// Resets this [Pagination] to its initial state.
  void clear() {
    pages.clear();
    hasNext.value = true;
    hasPrevious.value = true;
  }

  /// Fetches the [Page] around the provided [item] or [cursor].
  ///
  /// If neither [item] nor [cursor] is provided, then fetches the first [Page].
  FutureOr<void> around({T? item, K? cursor}) async {
    clear();

    final Page<T, K> page = await provider.around(item, cursor, perPage);
    if (page.info != null) {
      pages.add(page);
      hasNext.value = page.info!.hasNext;
      hasPrevious.value = page.info!.hasPrevious;
    } else {
      hasNext.value = false;
      hasPrevious.value = false;
    }
  }

  FutureOr<void> next() async {
    if (pages.isEmpty) {
      return around();
    }

    if (pages.last.info?.hasNext != false) {
      final Page<T, K> page = await provider.after(pages.last, perPage);
      if (page.info?.startCursor != null) {
        pages.add(page);
        hasNext.value = page.info!.hasNext;
      } else {
        hasNext.value = false;
      }
    }
  }

  FutureOr<void> previous() async {
    if (pages.isEmpty) {
      return around();
    }

    if (pages.first.info?.hasPrevious != false) {
      final Page<T, K> page = await provider.before(pages.first, perPage);
      if (page.info?.endCursor != null) {
        pages.insert(0, page);
        hasPrevious.value = page.info!.hasPrevious;
      } else {
        hasPrevious.value = false;
      }
    }
  }
}

class Page<T, K> {
  Page(this.edges, [this.info]);

  final RxList<T> edges;

  PageInfo<K>? info;
}

abstract class PageProvider<T, K> {
  FutureOr<Page<T, K>> around(T? item, K? cursor, int count);

  FutureOr<Page<T, K>> after(Page<T, K> page, int count);

  FutureOr<Page<T, K>> before(Page<T, K> page, int count);
}

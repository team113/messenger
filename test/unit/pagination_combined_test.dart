// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:messenger/store/model/page_info.dart';
import 'package:messenger/store/pagination.dart';
import 'package:messenger/store/pagination/combined_pagination.dart';

void main() async {
  test('CombinedPagination correctly invokes its methods', () async {
    final Pagination<int, int, int> pagination1 = Pagination(
      perPage: 4,
      provider: _ListPageProvider(count: 7),
      onKey: (i) => i,
      compare: (a, b) => a.compareTo(b),
    );

    final Pagination<int, int, int> pagination2 = Pagination(
      perPage: 4,
      provider: _ListPageProvider(count: 7, start: 7),
      onKey: (i) => i,
      compare: (a, b) => a.compareTo(b),
    );

    final CombinedPagination<int, int> combinedPagination = CombinedPagination([
      CombinedPaginationEntry(pagination1),
      CombinedPaginationEntry(pagination2),
    ]);

    await combinedPagination.around();
    expect(combinedPagination.items.length, 4);
    expect(combinedPagination.items, [0, 1, 2, 3]);
    expect(combinedPagination.hasNext.value, true);

    await combinedPagination.next();
    expect(combinedPagination.items.length, 7);
    expect(combinedPagination.items, [0, 1, 2, 3, 4, 5, 6]);
    expect(combinedPagination.hasNext.value, true);

    await combinedPagination.next();
    expect(combinedPagination.items.length, 11);
    expect(combinedPagination.items, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    expect(combinedPagination.hasNext.value, true);

    await combinedPagination.next();
    expect(combinedPagination.items.length, 14);
    expect(combinedPagination.items, [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
    ]);
    expect(combinedPagination.hasNext.value, false);
  });
}

class _ListPageProvider implements PageProvider<int, int, int> {
  _ListPageProvider({int start = 0, required int count})
    : _items = List.generate(count, (i) => start + i);

  final List<int> _items;

  @override
  Future<Page<int, int>?> init(int? item, int count) async => null;

  @override
  void dispose() {
    // No-op.
  }

  @override
  FutureOr<Page<int, int>> around(int? item, int? cursor, int count) {
    final int half = count ~/ 2;

    cursor ??= half;

    int before = half;
    if (cursor - before < 0) {
      before = cursor;
    }

    int after = half;
    if (cursor + after > _items.length) {
      after = _items.length - cursor;
    }

    return Page(
      RxList(_items.skip(cursor - before).take(before + after).toList()),
      PageInfo<int>(
        hasPrevious: cursor - before > 0,
        hasNext: cursor + after < _items.length,
        startCursor: cursor - before,
        endCursor: cursor + after - 1,
      ),
    );
  }

  @override
  FutureOr<Page<int, int>> after(int? value, int? cursor, int count) {
    cursor ??= 0;

    if (cursor + 1 + count > _items.length) {
      count = _items.length - cursor - 1;
    }

    return Page(
      RxList(_items.skip(cursor + 1).take(count).toList()),
      PageInfo<int>(
        hasPrevious: cursor + 1 > 0,
        hasNext: cursor + 1 + count < _items.length,
        startCursor: cursor + 1,
        endCursor: cursor + count,
      ),
    );
  }

  @override
  FutureOr<Page<int, int>> before(int? item, int? cursor, int count) {
    cursor ??= 0;

    if (cursor - count < 0) {
      count = cursor;
    }

    return Page(
      RxList(_items.skip(cursor - count).take(count).toList()),
      PageInfo<int>(
        hasPrevious: cursor - count > 0,
        hasNext: cursor < _items.length,
        startCursor: cursor - count,
        endCursor: cursor - 1,
      ),
    );
  }

  @override
  Future<void> put(
    Iterable<int> items, {
    bool ignoreBounds = false,
    int Function(int, int)? compare,
  }) async {}

  @override
  Future<void> remove(int key) async {}

  @override
  Future<void> clear() async {}
}

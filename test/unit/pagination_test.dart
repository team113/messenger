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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:messenger/store/model/page_info.dart';
import 'package:messenger/store/pagination.dart';

void main() async {
  test('Parsing UserPhone successfully', () async {
    final Pagination<int, int, int> pagination = Pagination(
      perPage: 4,
      provider: _ListPageProvider(),
      onKey: (i) => i,
    );

    void console() {
      print(
        '[${pagination.items.values}] (${pagination.startCursor} to ${pagination.endCursor})',
      );
    }

    await pagination.around(cursor: 20);
    console();

    await pagination.next();
    console();

    await pagination.previous();
    console();

    print(
      'hasPrevious: ${pagination.hasPrevious.value}, hasNext: ${pagination.hasNext.value}',
    );
  });
}

class _ListPageProvider implements PageProvider<int, int> {
  final List<int> _items = List.generate(50, (i) => i);

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
  Future<void> put(int item) async {}
}

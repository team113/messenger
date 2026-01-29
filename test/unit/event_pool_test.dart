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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:messenger/util/event_pool.dart';

void main() {
  test('EventPool locks the correct values', () async {
    final pool = EventPool();

    pool.protect(
      'tag',
      () => Future.delayed(const Duration(seconds: 2)),
      values: ['value', 'value1'],
    );
    await Future.delayed(Duration.zero);

    expect(pool.lockedWith('tag', 'value'), true);
    expect(pool.lockedWith('tag', 'value1'), true);
    expect(pool.lockedWith('1', 'value'), false);
    expect(pool.lockedWith('tag', '1'), false);
  });

  test('EventPool.protect() does nothing, if executing the same tag', () async {
    final pool = EventPool();

    pool.protect(
      'tag',
      () => Future.delayed(const Duration(seconds: 2)),
      values: ['value'],
    );

    final startedAt = DateTime.now();

    await pool.protect(
      'tag',
      () => Future.delayed(const Duration(seconds: 2)),
      values: ['value'],
    );

    expect(DateTime.now().difference(startedAt) < 15.milliseconds, true);
  });

  test('EventPool.processed() returns expected results', () async {
    final pool = EventPool();

    pool.add('processed');
    expect(pool.processed('processed'), true);
    expect(pool.processed('processed'), false);
    expect(pool.processed('processed1'), false);
  });

  test('EventPool.protect() repeats the provided callback', () async {
    int i = 10;
    final pool = EventPool();

    await pool.protect('tag', () async => i--, repeat: () => i > 0);

    expect(i, 0);
  });

  test('EventPool.protect() stops repeating, if disposed', () async {
    final pool = EventPool();

    pool.protect(
      'tag',
      () => Future.delayed(const Duration(milliseconds: 100)),
      repeat: () => true,
      values: ['value'],
    );
    pool.dispose();

    await Future.delayed(const Duration(milliseconds: 200));

    expect(pool.lockedWith('tag', 'value'), false);
  });
}

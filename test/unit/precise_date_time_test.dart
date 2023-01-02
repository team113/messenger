// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'package:messenger/domain/model/precise_date_time/src/web.dart';

void main() async {
  test('PreciseDateTime returns correct results', () {
    PreciseDateTime val1 = PreciseDateTime.parse('2022-06-03T12:38:34.366158Z');
    PreciseDateTime val2 = PreciseDateTime.parse('2022-06-03T12:38:34.366Z');
    PreciseDateTime val3 = PreciseDateTime.parse('2022-06-03T12:38:34.366000Z');
    PreciseDateTime val4 = PreciseDateTime.parse('2022-06-03T12:38:35Z');
    PreciseDateTime val5 = PreciseDateTime.parse('2022-06-03T12:38:34.366750Z');

    expect(val1.isBefore(val2), false);
    expect(val1.isAfter(val2), true);
    expect(val1.microsecondsSinceEpoch == val2.microsecondsSinceEpoch, false);
    expect(
      val1.add(const Duration(seconds: 3)).microsecondsSinceEpoch,
      1654259917366158,
    );
    expect(
      val1.subtract(const Duration(seconds: 3)).microsecondsSinceEpoch,
      1654259911366158,
    );
    expect(val1.toString(), '2022-06-03 12:38:34.366158Z');

    expect(val2.microsecondsSinceEpoch == val3.microsecondsSinceEpoch, true);
    expect(val2.isBefore(val4), true);
    expect(val4.microsecondsSinceEpoch > val2.microsecondsSinceEpoch, true);
    expect(val1.add(const Duration(seconds: 3)).microsecondsSinceEpoch,
        1654259917366158);
    expect(val1.subtract(const Duration(seconds: 3)).microsecondsSinceEpoch,
        1654259911366158);
    expect(val5.isAfter(val1), true);
    expect(val1.toString(), '2022-06-03 12:38:34.366158Z');
    expect(val2.toString(), '2022-06-03 12:38:34.366Z');

    expect(val3.toString(), '2022-06-03 12:38:34.366Z');

    expect(val4.isAfter(val1), true);
    expect(val4.microsecondsSinceEpoch > val2.microsecondsSinceEpoch, true);
    expect(val4.toString(), '2022-06-03 12:38:35.000Z');
    expect(val5.toString(), '2022-06-03 12:38:34.366750Z');

    expect(
      PreciseDateTime.parse('2022-06-03T12:38:34.366158Z').toString(),
      '2022-06-03 12:38:34.366158Z',
    );

    expect(
      PreciseDateTime.parse('2022-06-03T12:38:34.366Z').toString(),
      '2022-06-03 12:38:34.366Z',
    );

    expect(
      PreciseDateTime.parse('2022-06-03T12:38:34.366000Z').toString(),
      '2022-06-03 12:38:34.366Z',
    );

    expect(
      PreciseDateTime.parse('2022-06-03T12:38:35Z').toString(),
      '2022-06-03 12:38:35.000Z',
    );

    expect(
      PreciseDateTime.parse('2022-06-03T12:38:34.366750Z').toString(),
      '2022-06-03 12:38:34.366750Z',
    );

    expect(
      PreciseDateTime.parse('2022-06-03 12:38:34.366750Z').toString(),
      '2022-06-03 12:38:34.366750Z',
    );

    var val6 = PreciseDateTime.parse('2022-06-03 12:38:34.366750Z');
    expect(val6.val.hour, 12);
    expect(val6.val.minute, 38);
    expect(val6.val.second, 34);
    expect(val6.val.millisecond, 366);
    expect(val6.microsecond, 750);

    var val7 = PreciseDateTime.parse('2021-07-04T13:39:35.477Z');
    expect(val7.val.hour, 13);
    expect(val7.val.minute, 39);
    expect(val7.val.second, 35);
    expect(val7.val.millisecond, 477);
    expect(val7.microsecond, 0);
  });
}

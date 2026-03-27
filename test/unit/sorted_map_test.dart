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

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/util/obs/obs.dart';

void main() {
  test('SortedObsMap sorts inserted values correctly', () {
    final SortedObsMap<int, _Pair> map = SortedObsMap((a, b) {
      final int compare = a.sortBy.compareTo(b.sortBy);
      if (compare == 0) {
        return a.value.compareTo(b.value);
      }

      return compare;
    });

    map[0] = const _Pair('value0', 0);
    map[1] = const _Pair('value1', -1);
    map[2] = const _Pair('value2', 1);
    map[3] = const _Pair('value3', -2);
    map[4] = const _Pair('value4', 2);
    map.addEntries(const [
      MapEntry(6, _Pair('value5', 10)),
      MapEntry(7, _Pair('value6', -5)),
      MapEntry(8, _Pair('value7', 32)),
      MapEntry(9, _Pair('value8', 0)),
    ]);

    expect(map.remove(2) != null, true);

    expect(
      const ListEquality().equals(map.keys.toList(), [0, 1, 3, 4, 6, 7, 8, 9]),
      true,
    );

    expect(
      const ListEquality().equals(map.values.map((e) => e.sortBy).toList(), [
        -5,
        -2,
        -1,
        0,
        0,
        2,
        10,
        32,
      ]),
      true,
    );
  });
}

class _Pair {
  const _Pair(this.value, this.sortBy);

  final String value;
  final int sortBy;

  @override
  String toString() => '($value, $sortBy)';
}

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

import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  L10n.chosen.value = 'en_US';
  await L10n.load();
  test('DateTime.toRelative returns correct representations', () {
    expect(
      DateTime(2022, 2, 17, 13, 40).toRelative(DateTime(2022, 2, 17, 13, 40)),
      '13:40',
    );

    expect(
      DateTime(2022, 2, 17, 13, 40).toRelative(DateTime(2022, 2, 17, 14, 00)),
      '13:40',
    );

    expect(
      DateTime(2022, 2, 17, 13, 40).toRelative(DateTime(2022, 2, 17, 23, 59)),
      '13:40',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 17, 23, 59)),
      '00:00',
    );

    expect(
      DateTime(2022, 2, 17, 23, 59).toRelative(DateTime(2022, 2, 18)),
      'Yesterday, 23:59',
    );

    expect(
      DateTime(2022, 2, 17, 23, 59).toRelative(DateTime(2022, 2, 18, 23, 59)),
      'Yesterday, 23:59',
    );

    expect(
      DateTime(2022, 2, 28).toRelative(DateTime(2022, 3, 1)),
      'Yesterday, 00:00',
    );

    expect(
      DateTime(2022, 2, 28).toRelative(DateTime(2022, 3, 2)),
      '2 days ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17, 23, 59).toRelative(DateTime(2022, 2, 19)),
      '2 days ago, 23:59',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 20, 23, 59)),
      '3 days ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 21, 23, 59)),
      '4 days ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 22, 23, 59)),
      '5 days ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 23, 23, 59)),
      '6 days ago, 00:00',
    );

    expect(
      DateTime(2022, 12, 31).toRelative(DateTime(2023)),
      'Yesterday, 00:00',
    );

    expect(
      DateTime(2022, 12, 31).toRelative(DateTime(2023, 1, 5)),
      '5 days ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 24)),
      'Week ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 3, 2)),
      'Week ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 3, 3)),
      '2 weeks ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 3, 17)),
      'Month ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 3, 31)),
      'Month ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 4, 1)),
      'Month ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 4, 16)),
      'Month ago, 00:00',
    );

    expect(
      DateTime(2021, 12, 24, 18, 09).toRelative(DateTime(2022, 2, 17, 15, 43)),
      'Month ago, 18:09',
    );

    expect(
      DateTime(2022, 1, 18, 15, 16).toRelative(DateTime(2022, 2, 18, 10, 21)),
      'Month ago, 15:16',
    );

    expect(
      DateTime(2022, 1, 19, 15, 16).toRelative(DateTime(2022, 2, 18, 10, 21)),
      '4 weeks ago, 15:16',
    );

    expect(
      DateTime(2022, 1, 21, 15, 16).toRelative(DateTime(2022, 2, 18, 10, 21)),
      '4 weeks ago, 15:16',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 4, 17)),
      '2 months ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2023, 2, 16)),
      '11 months ago, 00:00',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2023, 2, 17)),
      'Year ago, 00:00',
    );

    expect(
      DateTime(2022, 3).toRelative(DateTime(2023, 3)),
      'Year ago, 00:00',
    );

    expect(
      DateTime(2022).toRelative(DateTime(2023)),
      'Year ago, 00:00',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2023, 12, 12)),
      '11 months ago, 00:00',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2023, 12, 13)),
      'Year ago, 00:00',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2024, 12, 12)),
      'Year ago, 00:00',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2024, 12, 12)),
      'Year ago, 00:00',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2024, 12, 13)),
      '2 years ago, 00:00',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2025, 12, 12)),
      '2 years ago, 00:00',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2025, 12, 13)),
      '3 years ago, 00:00',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2026, 12, 12)),
      '3 years ago, 00:00',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2026, 12, 13)),
      '4 years ago, 00:00',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2027, 12, 12)),
      '4 years ago, 00:00',
    );

    expect(
      DateTime(2017, 9, 7, 17, 30).toRelative(DateTime(2022, 9, 7, 17, 30)),
      '5 years ago, 17:30',
    );

    expect(
      DateTime(2017, 9, 7, 17, 30).toRelative(DateTime(2023, 01, 01)),
      '5 years ago, 17:30',
    );

    expect(
      DateTime(2017, 9, 7, 17, 30).toRelative(DateTime(2023, 9, 7, 17, 30)),
      '6 years ago, 17:30',
    );

    expect(
      DateTime(1970, 2, 17).toRelative(DateTime(2100, 2, 17)),
      '130 years ago, 00:00',
    );
  });
}

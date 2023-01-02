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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/recent_chat.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DateTime.toShort returns correct representations', () async {
    await L10n.init(L10n.languages.first);

    final DateTime now = DateTime.now();

    expect(
      DateTime(now.year, now.month, now.day, now.hour, now.minute).toShort(),
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );

    expect(
      DateTime(now.year, now.month, now.day, 23, 59).toShort(),
      '23:59',
    );

    expect(
      DateTime(now.year, now.month, now.day, 0, 1).toShort(),
      '00:01',
    );

    final DateTime yesterday = now.subtract(1.days);

    expect(
      DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        yesterday.hour,
        yesterday.minute,
      ).toShort(),
      'label_short_weekday'.l10nfmt({'weekday': yesterday.weekday}),
    );

    expect(
      DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59)
          .toShort(),
      'label_short_weekday'.l10nfmt({'weekday': yesterday.weekday}),
    );

    expect(
      DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 1).toShort(),
      'label_short_weekday'.l10nfmt({'weekday': yesterday.weekday}),
    );

    final DateTime sixDaysAgo = now.subtract(6.days);

    expect(
      DateTime(
        sixDaysAgo.year,
        sixDaysAgo.month,
        sixDaysAgo.day,
        sixDaysAgo.hour,
        sixDaysAgo.minute,
      ).toShort(),
      'label_short_weekday'.l10nfmt({'weekday': sixDaysAgo.weekday}),
    );

    expect(
      DateTime(sixDaysAgo.year, sixDaysAgo.month, sixDaysAgo.day, 23, 59)
          .toShort(),
      'label_short_weekday'.l10nfmt({'weekday': sixDaysAgo.weekday}),
    );

    expect(
      DateTime(sixDaysAgo.year, sixDaysAgo.month, sixDaysAgo.day, 0, 1)
          .toShort(),
      'label_short_weekday'.l10nfmt({'weekday': sixDaysAgo.weekday}),
    );

    final DateTime sevenDaysAgo = now.subtract(7.days);

    expect(
      DateTime(
        sevenDaysAgo.year,
        sevenDaysAgo.month,
        sevenDaysAgo.day,
        sevenDaysAgo.hour,
        sevenDaysAgo.minute,
      ).toShort(),
      '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}',
    );

    expect(
      DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day, 23, 59)
          .toShort(),
      '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}',
    );

    expect(
      DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day, 0, 1)
          .toShort(),
      '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}',
    );

    final DateTime monthAgo = now.subtract(31.days);
    String month = monthAgo.month.toString().padLeft(2, '0');
    String day = monthAgo.day.toString().padLeft(2, '0');

    expect(
      DateTime(
        monthAgo.year,
        monthAgo.month,
        monthAgo.day,
        monthAgo.hour,
        monthAgo.minute,
      ).toShort(),
      '${monthAgo.year}-$month-$day',
    );

    final DateTime yearAgo = now.subtract(366.days);
    month = yearAgo.month.toString().padLeft(2, '0');
    day = yearAgo.day.toString().padLeft(2, '0');

    expect(
      DateTime(
        yearAgo.year,
        yearAgo.month,
        yearAgo.day,
        yearAgo.hour,
        yearAgo.minute,
      ).toShort(),
      '${yearAgo.year}-$month-$day',
    );
  });
}

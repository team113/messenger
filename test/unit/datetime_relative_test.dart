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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DateTime.toRelative returns correct representations', () async {
    await L10n.init(L10n.languages.first);

    expect(
      DateTime(2022, 2, 17, 13, 40).toRelative(DateTime(2022, 2, 17, 13, 40)),
      'Today',
    );

    expect(
      DateTime(2022, 2, 17, 13, 40).toRelative(DateTime(2022, 2, 17, 14, 00)),
      'Today',
    );

    expect(
      DateTime(2022, 2, 17, 13, 40).toRelative(DateTime(2022, 2, 17, 23, 59)),
      'Today',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 17, 23, 59)),
      'Today',
    );

    expect(
      DateTime(2022, 2, 17, 23, 59).toRelative(DateTime(2022, 2, 18)),
      'Yesterday',
    );

    expect(
      DateTime(2022, 2, 17, 23, 59).toRelative(DateTime(2022, 2, 18, 23, 59)),
      'Yesterday',
    );

    expect(
      DateTime(2022, 2, 28).toRelative(DateTime(2022, 3, 1)),
      'Yesterday',
    );

    expect(
      DateTime(2022, 2, 28).toRelative(DateTime(2022, 3, 2)),
      '2 days ago',
    );

    expect(
      DateTime(2022, 2, 17, 23, 59).toRelative(DateTime(2022, 2, 19)),
      '2 days ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 20, 23, 59)),
      '3 days ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 21, 23, 59)),
      '4 days ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 22, 23, 59)),
      '5 days ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 23, 23, 59)),
      '6 days ago',
    );

    expect(
      DateTime(2022, 12, 31).toRelative(DateTime(2023)),
      'Yesterday',
    );

    expect(
      DateTime(2022, 12, 31).toRelative(DateTime(2023, 1, 5)),
      '5 days ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 2, 24)),
      'A week ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 3, 2)),
      'A week ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 3, 3)),
      '2 weeks ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 3, 17)),
      'A month ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 3, 31)),
      'A month ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 4, 1)),
      'A month ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 4, 16)),
      'A month ago',
    );

    expect(
      DateTime(2021, 12, 24, 18, 09).toRelative(DateTime(2022, 2, 17, 15, 43)),
      'A month ago',
    );

    expect(
      DateTime(2022, 1, 18, 15, 16).toRelative(DateTime(2022, 2, 18, 10, 21)),
      'A month ago',
    );

    expect(
      DateTime(2022, 1, 19, 15, 16).toRelative(DateTime(2022, 2, 18, 10, 21)),
      '4 weeks ago',
    );

    expect(
      DateTime(2022, 1, 21, 15, 16).toRelative(DateTime(2022, 2, 18, 10, 21)),
      '4 weeks ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2022, 4, 17)),
      '2 months ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2023, 2, 16)),
      '11 months ago',
    );

    expect(
      DateTime(2022, 2, 17).toRelative(DateTime(2023, 2, 17)),
      'An year ago',
    );

    expect(
      DateTime(2022, 3).toRelative(DateTime(2023, 3)),
      'An year ago',
    );

    expect(
      DateTime(2022).toRelative(DateTime(2023)),
      'An year ago',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2023, 12, 12)),
      '11 months ago',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2023, 12, 13)),
      'An year ago',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2024, 12, 12)),
      'An year ago',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2024, 12, 12)),
      'An year ago',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2024, 12, 13)),
      '2 years ago',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2025, 12, 12)),
      '2 years ago',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2025, 12, 13)),
      '3 years ago',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2026, 12, 12)),
      '3 years ago',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2026, 12, 13)),
      '4 years ago',
    );

    expect(
      DateTime(2022, 12, 13).toRelative(DateTime(2027, 12, 12)),
      '4 years ago',
    );

    expect(
      DateTime(2017, 9, 7, 17, 30).toRelative(DateTime(2022, 9, 7, 17, 30)),
      '5 years ago',
    );

    expect(
      DateTime(2017, 9, 7, 17, 30).toRelative(DateTime(2023, 01, 01)),
      '5 years ago',
    );

    expect(
      DateTime(2017, 9, 7, 17, 30).toRelative(DateTime(2023, 9, 7, 17, 30)),
      '6 years ago',
    );

    expect(
      DateTime(1970, 2, 17).toRelative(DateTime(2100, 2, 17)),
      '130 years ago',
    );
  });
}

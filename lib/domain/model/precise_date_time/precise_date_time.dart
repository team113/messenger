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

import 'package:messenger/l10n/l10n.dart';

import 'src/non_web.dart' if (dart.library.html) 'src/web.dart';

export 'src/non_web.dart' if (dart.library.html) 'src/web.dart';

/// Extension adding [DateTime] to [PreciseDateTime] conversion method.
extension DateTimeToPreciseDateTime on DateTime {
  /// Constructs a [PreciseDateTime] from this [DateTime].
  PreciseDateTime toPrecise() => PreciseDateTime(this);
}

/// Extension adding conversion to date from a [PreciseDateTime].
extension AdditionalFormatting on PreciseDateTime {
  /// Converts [PreciseDateTime] to a date string or day of the week.
  ///
  /// If the date is less than a week, then output the day of the week, otherwise the date in the format yyyy-mm-dd.
  String toDateAndWeekday() {
    final DateTime pastWeek = DateTime.now().subtract(const Duration(days: 7));
    if (val.isBefore(pastWeek)) {
      final String day = val.day.toString().padLeft(2, '0');
      final String month = val.month.toString().padLeft(2, '0');
      return '${val.year}-$month-$day';
    } else {
      return 'label_abbreviation_weekday_${val.weekday}'.l10n;
    }
  }
}

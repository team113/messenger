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

import '/l10n/l10n.dart';

extension FileSizeExtension on num {
  String formatFileSize() {
    final List<String> suffixes = <String>[
      ('label_b'.l10n),
      ('label_kb'.l10n),
      ('label_mb'.l10n),
      ('label_gb'.l10n),
      ('label_tb'.l10n),
      ('label_pb'.l10n),
    ];

    int index = 0;
    double value = toDouble();

    if (this < 0) {
      return '0';
    }
    if (value < 1024) {
      return '${value.toInt()} ${suffixes[0]}';
    }
    while (value >= 1024 && index < suffixes.length - 1) {
      value /= 1024;
      index++;
    }

    final formattedValue = value.toStringAsFixed(1);

    return '$formattedValue${'space'.l10n}${suffixes[index]}';
  }
}

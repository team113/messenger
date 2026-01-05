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

import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/l10n/l10n.dart';

void main() {
  test('L10nSizeInBytesExtension.asBytes() properly formats the sizes', () async {
    WidgetsFlutterBinding.ensureInitialized(); // Required to load translations.

    await L10n.init(L10n.languages.first);

    expect(null.asBytes(), 'dot'.l10n * 3);
    expect(0.asBytes(), 'label_b'.l10nfmt({'amount': '0'}));
    expect(1023.asBytes(), 'label_b'.l10nfmt({'amount': '1023'}));
    expect(1024.asBytes(), 'label_kb'.l10nfmt({'amount': '1.0'}));
    expect((1024 + 50).asBytes(), 'label_kb'.l10nfmt({'amount': '1.0'}));
    expect((1024 + 100).asBytes(), 'label_kb'.l10nfmt({'amount': '1.1'}));
    expect(
      pow(1024, 2).toInt().asBytes(),
      'label_mb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 3).toInt().asBytes(),
      'label_gb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 4).toInt().asBytes(),
      'label_tb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 5).toInt().asBytes(),
      'label_pb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 6).toInt().asBytes(),
      'label_pb'.l10nfmt({'amount': '1024.0'}),
    );
  });
}

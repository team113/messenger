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
import 'package:messenger/util/file_size.dart';
import 'package:messenger/l10n/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FileSizeExtension.formatFileSize properly formats file sizes',
      () async {
    await L10n.init(L10n.languages.first);

    const int b = 512;
    expect(b.formatFileSize(), '512 B');

    const int kB = 524288;
    expect(kB.formatFileSize(), '512.0 KB');

    const int mB = 536870912;
    expect(mB.formatFileSize(), '512.0 MB');

    const int gB = 549755813888;
    expect(gB.formatFileSize(), '512.0 GB');

    const int tB = 562949950000000;
    expect(tB.formatFileSize(), '512.0 TB');

    const int pB = 576460750000000000;
    expect(pB.formatFileSize(), '512.0 PB');

    const int negative = -1000;
    expect(negative.formatFileSize(), '0');
  });
}

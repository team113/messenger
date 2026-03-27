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
import 'package:messenger/ui/worker/upgrade.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Rfc822ToDateTime.tryParse() returns correct results', () async {
    expect(
      Rfc822ToDateTime.tryParse('Wed, 20 Mar 2024 12:00:03 +0300')?.toUtc(),
      DateTime.utc(2024, 03, 20, 12 - 03, 00, 03),
    );

    expect(
      Rfc822ToDateTime.tryParse('Sun, 1 Jun 2024 15:10:51 +0000')?.toUtc(),
      DateTime.utc(2024, 06, 01, 15, 10, 51),
    );

    expect(
      Rfc822ToDateTime.tryParse('Tue, 5 Dec 2000 01:02:03 GMT')?.toUtc(),
      DateTime.utc(2000, 12, 05, 01, 02, 03),
    );

    expect(
      Rfc822ToDateTime.tryParse('1 Sep 2007 23:23:59 +0100')?.toUtc(),
      DateTime.utc(2007, 09, 01, 22, 23, 59),
    );
  });
}

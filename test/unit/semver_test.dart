// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

  test('SemVer correctly detects the critical versions', () async {
    expect(SemVer(0, 1, 0, '-alpha.1').isCritical(SemVer(0, 1, 0)), true);
    expect(SemVer(0, 1, 0).isCritical(SemVer(0, 2, 0, '-alpha.1')), false);
    expect(SemVer(0, 1, 0, '-alpha.1').isCritical(SemVer(0, 2, 0)), true);

    expect(SemVer(0, 1, 0).isCritical(SemVer(1, 0, 0, '-alpha.5')), false);
    expect(SemVer(0, 1, 0, '-alpha.5').isCritical(SemVer(1, 0, 0)), true);
    expect(SemVer(0, 1, 0).isCritical(SemVer(1, 0, 0)), true);
    expect(SemVer(1, 0, 0).isCritical(SemVer(2, 0, 0, '-beta.2')), false);
    expect(SemVer(1, 0, 0).isCritical(SemVer(2, 0, 0, '-rc.4')), false);

    expect(
      SemVer(0, 1, 0, '-alpha.1').isCritical(SemVer(0, 1, 0, '-alpha.2')),
      true,
    );

    expect(
      SemVer(0, 1, 0, '-alpha.1').isCritical(SemVer(0, 1, 0, '-alpha.1')),
      false,
    );

    expect(
      SemVer(0, 1, 0, '-alpha.2').isCritical(SemVer(0, 1, 0, '-alpha.1')),
      false,
    );

    expect(
      SemVer(0, 1, 0, '-alpha.1').isCritical(SemVer(0, 1, 0, '-beta.1')),
      true,
    );

    expect(
      SemVer(0, 1, 0, '-alpha.1').isCritical(SemVer(0, 1, 0, '-rc.1')),
      true,
    );

    expect(
      SemVer(0, 1, 0, '-alpha.1').isCritical(SemVer(0, 1, 0, '-rc.1')),
      true,
    );

    expect(
      SemVer(0, 1, 0, '-alpha.1').isCritical(SemVer(0, 1, 0, '-alpha')),
      false,
    );

    expect(
      SemVer(0, 1, 0, '-alpha').isCritical(SemVer(0, 1, 0, '-alpha.1')),
      true,
    );

    expect(
      SemVer(0, 1, 0, '-alpha.1').isCritical(SemVer(0, 1, 0, '-alpha.1.1')),
      false,
    );

    expect(
      SemVer(1, 23, 4, '-beta.54').isCritical(SemVer(1, 23, 4, '-alpha.54.9')),
      false,
    );

    expect(
      SemVer(1, 23, 4, '-beta.54').isCritical(SemVer(1, 23, 4, '-beta.54.9')),
      false,
    );

    expect(
      SemVer(1, 23, 4, '-beta.54').isCritical(SemVer(1, 23, 4, '-beta.55.6')),
      true,
    );

    expect(
      SemVer(1, 23, 4, '-beta.54.6').isCritical(SemVer(1, 23, 4, '-beta.55.6')),
      true,
    );
  });
}

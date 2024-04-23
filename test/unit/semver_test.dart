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

  test('SemVer correctly parses versions', () async {
    var str = '0.1.0';
    var ver = SemVer.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 0);
    expect(ver.minor, 1);
    expect(ver.patch, 0);
    expect(ver.suffix, null);

    str = '1.2.3';
    ver = SemVer.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 1);
    expect(ver.minor, 2);
    expect(ver.patch, 3);
    expect(ver.suffix, null);

    str = '1.2.3-alpha.1';
    ver = SemVer.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 1);
    expect(ver.minor, 2);
    expect(ver.patch, 3);
    expect(ver.suffix, '-alpha.1');

    str = '123.456.789-beta.2512';
    ver = SemVer.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 123);
    expect(ver.minor, 456);
    expect(ver.patch, 789);
    expect(ver.suffix, '-beta.2512');

    str = 'not.a.sem-ver';
    expect(() => SemVer.parse(str), throwsA(isA<FormatException>()));

    str = '1.awd.123.fwq';
    expect(() => SemVer.parse(str), throwsA(isA<FormatException>()));

    str = '0';
    expect(() => SemVer.parse(str), throwsA(isA<FormatException>()));

    str = '0.1';
    expect(() => SemVer.parse(str), throwsA(isA<FormatException>()));

    str = '0';
    expect(() => SemVer.parse(str), throwsA(isA<FormatException>()));
  });

  test('SemVer correctly compares the versions', () async {
    expect(SemVer(0, 1, 0).compareTo(SemVer(0, 1, 0)), 0);
    expect(SemVer(1, 2, 3).compareTo(SemVer(1, 2, 3)), 0);
    expect(SemVer(0, 1, 0).compareTo(SemVer(0, 1, 1)), -1);
    expect(SemVer(0, 1, 1).compareTo(SemVer(0, 1, 0)), 1);
  });
}

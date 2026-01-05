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
import 'package:pub_semver/pub_semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Version correctly parses versions', () async {
    var str = '0.1.0';
    var ver = Version.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 0);
    expect(ver.minor, 1);
    expect(ver.patch, 0);
    expect(ver.preRelease, []);
    expect(ver.build, []);

    str = '1.2.3';
    ver = Version.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 1);
    expect(ver.minor, 2);
    expect(ver.patch, 3);
    expect(ver.preRelease, []);
    expect(ver.build, []);

    str = '1.2.3-alpha.1';
    ver = Version.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 1);
    expect(ver.minor, 2);
    expect(ver.patch, 3);
    expect(ver.preRelease, ['alpha', 1]);
    expect(ver.build, []);

    str = '123.456.789-beta.2512';
    ver = Version.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 123);
    expect(ver.minor, 456);
    expect(ver.patch, 789);
    expect(ver.preRelease, ['beta', 2512]);
    expect(ver.build, []);

    str = '123.456.789-beta.2512+123.3';
    ver = VersionExtension.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 123);
    expect(ver.minor, 456);
    expect(ver.patch, 789);
    expect(ver.preRelease, ['beta', 2512]);
    expect(ver.build, [123, 3]);

    str = 'not.a.sem-ver';
    expect(() => Version.parse(str), throwsA(isA<FormatException>()));

    str = '1.awd.123.fwq';
    expect(() => Version.parse(str), throwsA(isA<FormatException>()));

    str = '0';
    expect(() => Version.parse(str), throwsA(isA<FormatException>()));

    str = '0.1';
    expect(() => Version.parse(str), throwsA(isA<FormatException>()));

    str = '0';
    expect(() => Version.parse(str), throwsA(isA<FormatException>()));

    str = '-1.2.3';
    expect(() => Version.parse(str), throwsA(isA<FormatException>()));
  });

  test('VersionExtension correctly parses versions', () async {
    var str = '0.1.0';
    var ver = VersionExtension.parse(str);
    expect(ver.major, 0);
    expect(ver.minor, 1);
    expect(ver.patch, 0);
    expect(ver.preRelease, []);
    expect(ver.build, []);

    str = '1.2.3';
    ver = VersionExtension.parse(str);
    expect(ver.major, 1);
    expect(ver.minor, 2);
    expect(ver.patch, 3);
    expect(ver.preRelease, []);
    expect(ver.build, []);

    str = '1.2.3-alpha.1';
    ver = VersionExtension.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 1);
    expect(ver.minor, 2);
    expect(ver.patch, 3);
    expect(ver.preRelease, ['alpha', 1]);
    expect(ver.build, []);

    str = '123.456.789-beta.2512';
    ver = VersionExtension.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 123);
    expect(ver.minor, 456);
    expect(ver.patch, 789);
    expect(ver.preRelease, ['beta', 2512]);
    expect(ver.build, []);

    str = '123.456.789-beta.2512+123.3';
    ver = VersionExtension.parse(str);
    expect(ver.toString(), str);
    expect(ver.major, 123);
    expect(ver.minor, 456);
    expect(ver.patch, 789);
    expect(ver.preRelease, ['beta', 2512]);
    expect(ver.build, [123, 3]);
  });

  test('Version correctly compares the versions', () async {
    expect(Version(0, 1, 0) == Version(0, 1, 0), true);
    expect(Version(1, 2, 3) == Version(1, 2, 3), true);
    expect(Version(0, 1, 0) < Version(0, 1, 1), true);
    expect(Version(0, 1, 1) > Version(0, 1, 0), true);
    expect(Version(0, 1, 0, pre: 'alpha') < Version(0, 1, 0), true);
    expect(Version(0, 1, 0) > Version(0, 1, 0, pre: 'alpha'), true);
    expect(
      Version(0, 1, 0, pre: 'alpha') < Version(0, 1, 0, pre: 'beta'),
      true,
    );
    expect(
      Version(0, 1, 0, pre: 'beta') > Version(0, 1, 0, pre: 'alpha'),
      true,
    );
    expect(
      Version(0, 1, 0, pre: 'beta.2') > Version(0, 1, 0, pre: 'beta.1'),
      true,
    );
    expect(
      Version(0, 1, 0, pre: 'beta.10') > Version(0, 1, 0, pre: 'beta.1'),
      true,
    );
    expect(
      Version(0, 1, 0, pre: 'beta.10') < Version(0, 1, 0, pre: 'beta.11'),
      true,
    );
    expect(
      Version(0, 1, 0, pre: 'beta.10.1') > Version(0, 1, 0, pre: 'beta.10'),
      true,
    );
    expect(
      Version(0, 1, 0, pre: 'alpha.132.12') < Version(0, 1, 0, pre: 'beta.1'),
      true,
    );
    expect(
      Version(0, 1, 0, pre: 'beta.5') < Version(0, 1, 0, pre: 'rc.1'),
      true,
    );
    expect(Version(0, 1, 0, pre: 'beta.5') < Version(0, 1, 0, pre: 'rc'), true);
    expect(
      Version(0, 1, 0, pre: 'rc.1') > Version(0, 1, 0, pre: 'beta.5'),
      true,
    );
    expect(Version(0, 1, 0, pre: 'rc') > Version(0, 1, 0, pre: 'beta.5'), true);
    expect(Version(0, 1, 0, pre: 'rc.1') > Version(0, 1, 0, pre: 'rc'), true);
    expect(Version(0, 1, 0, pre: 'rc.2') > Version(0, 1, 0, pre: 'rc.1'), true);
    expect(Version(0, 1, 0, pre: 'rc') == Version(0, 1, 0, pre: 'rc'), true);
    expect(
      Version(0, 1, 0, pre: 'alpha.13.4') < Version(0, 1, 0, pre: 'alpha.13.5'),
      true,
    );

    expect(
      VersionExtension.parse('0.1.0-alpha.13-15-g0e28f1c14e-dirty') <
          VersionExtension.parse('0.1.0-alpha.14'),
      true,
    );
    expect(
      VersionExtension.parse('0.1.0-alpha.13-15') <
          VersionExtension.parse('0.1.0-alpha.14'),
      true,
    );

    expect(Version(0, 1, 0) < Version(0, 1, 0, build: '1'), true);
    expect(Version(0, 1, 0, build: '1') == Version(0, 1, 0, build: '1'), true);
    expect(Version(0, 1, 0, build: '1') < Version(0, 1, 0, build: '2'), true);
    expect(Version(1, 0, 0, build: '502') > Version(1, 0, 0, build: '9'), true);
  });

  test('Version correctly detects the critical versions', () async {
    expect(Version(0, 1, 0).isCritical(Version(0, 1, 0)), false);
    expect(Version(0, 1, 1).isCritical(Version(0, 1, 0)), false);
    expect(Version(0, 1, 0).isCritical(Version(0, 1, 1)), false);
    expect(Version(0, 2, 0).isCritical(Version(0, 1, 0)), false);
    expect(Version(0, 3, 0).isCritical(Version(0, 1, 0)), false);
    expect(Version(0, 1, 0).isCritical(Version(0, 3, 0)), true);
    expect(Version(0, 1, 0).isCritical(Version(1, 0, 0)), true);
    expect(Version(0, 1, 0).isCritical(Version(1, 2, 3)), true);
    expect(Version(1, 0, 0).isCritical(Version(1, 1, 0)), false);
    expect(Version(1, 0, 0).isCritical(Version(2, 0, 0)), true);
    expect(Version(1, 0, 0).isCritical(Version(3, 0, 0)), true);
    expect(Version(3, 0, 0).isCritical(Version(1, 0, 0)), false);
    expect(Version(1, 1, 2).isCritical(Version(5, 6, 7)), true);
    expect(Version(1, 1, 2).isCritical(Version(1, 55, 23)), false);
    expect(Version(0, 1, 0).isCritical(Version(1, 0, 0, pre: '-rc')), false);
    expect(Version(0, 1, 0, pre: 'rc').isCritical(Version(0, 1, 0)), true);
    expect(
      Version(0, 1, 0, pre: 'rc').isCritical(Version(1, 0, 0, pre: 'rc')),
      true,
    );
    expect(
      Version(
        0,
        1,
        0,
        pre: 'alpha.1',
      ).isCritical(Version(0, 1, 0, pre: 'alpha.2')),
      true,
    );
    expect(
      Version(
        0,
        1,
        0,
        pre: 'alpha.1',
      ).isCritical(Version(0, 1, 0, pre: 'alpha.1.1')),
      false,
    );
    expect(
      Version(
        0,
        1,
        0,
        pre: 'alpha.55.4',
      ).isCritical(Version(0, 1, 0, pre: 'beta.1')),
      true,
    );
    expect(
      Version(
        0,
        1,
        0,
        pre: 'alpha.55.4',
      ).isCritical(Version(0, 1, 0, pre: 'beta.56.6')),
      true,
    );
    expect(
      Version(
        0,
        1,
        0,
        pre: 'beta.54.3',
      ).isCritical(Version(0, 1, 0, pre: 'beta.54.12')),
      false,
    );
    expect(
      Version(
        0,
        1,
        0,
        pre: 'alpha.1',
      ).isCritical(Version(0, 1, 1, pre: 'alpha.1')),
      true,
    );
    expect(
      Version(0, 1, 0, pre: 'alpha').isCritical(Version(0, 1, 0, pre: 'rc')),
      true,
    );
    expect(
      Version(0, 1, 0, pre: 'alpha.54').isCritical(Version(0, 1, 0, pre: 'rc')),
      true,
    );
    expect(
      Version(0, 1, 0, pre: 'rc').isCritical(Version(0, 1, 0, pre: 'alpha.54')),
      false,
    );
    expect(
      Version(
        0,
        1,
        0,
        pre: 'beta.54.3',
      ).isCritical(Version(0, 1, 0, pre: 'beta.54.12')),
      false,
    );
    expect(
      Version(
        0,
        1,
        0,
        pre: 'beta.54.3',
      ).isCritical(Version(0, 1, 1, pre: 'beta.54.12')),
      true,
    );
    expect(
      Version(
        0,
        1,
        0,
        pre: 'beta.54.3',
      ).isCritical(Version(0, 2, 0, pre: 'beta.54.12')),
      true,
    );
    expect(
      Version(
        0,
        1,
        0,
        pre: 'alpha.1',
      ).isCritical(Version(0, 1, 0, pre: 'alpha.1', build: '1')),
      false,
    );
    expect(Version(0, 1, 0).isCritical(Version(0, 1, 0, build: '1')), false);
    expect(
      Version(0, 1, 0, build: '1').isCritical(Version(0, 1, 0, build: '2')),
      false,
    );
    expect(Version(1, 0, 0).isCritical(Version(1, 0, 0, build: '524')), false);
    expect(
      Version(0, 1, 0, build: '1').isCritical(Version(0, 2, 0, build: '2')),
      true,
    );
  });
}

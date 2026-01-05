// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/ui/page/home/page/my_profile/session/controller.dart';

void main() async {
  test('UserAgentExtension returns correct names of `User-Agent` header', () {
    Config.userAgentProduct = 'Tapopa';

    expect(
      const UserAgent(
        'Tapopa/0.1.0-alpha.8 (macOS Version 13.3.1 (Build 22E261); MacBookPro18,2; Darwin Kernel Version 22.4.0: Mon Mar  6 20:59:28 PST 2023; root:xnu-8796.101.5 ~3/RELEASE_ARM64_T6000; arm64 Apple M1 Max; E08855EB-C338-5EDC-B046-713AC743BA90)',
      ).localized,
      'MacBook Pro (16-inch, 2021)',
    );

    expect(
      const UserAgent(
        'Tapopa/0.1.0-alpha.8 (Windows 10 Pro; 21H2; build 19041.1.amd64fre.vb_release.191206-1406; x64; {487C0C09-4B5F-407F-9C26-313F31B79F06})',
      ).localized,
      'Windows 10 Pro',
    );

    expect(
      const UserAgent(
        'Tapopa/0.1.0-alpha.8 (Ubuntu 22.04 LTS; 5.15.0-48-generic; aarch64; 3787c48ab74047b28638ef2ddc97be6c)',
      ).localized,
      'Ubuntu 22.04 LTS',
    );

    expect(
      const UserAgent(
        'Tapopa/0.1.0-alpha.8 (Android 13; Xiaomi M2101K7BNY; V14.0.1.0.TKLRUXM (build Redmi/rosemary_ru/rosemary:13/TP1A.220624.014/V14.0.1.0.TKLRUXM:user/release-keys); SDK 33; aarch64 mt6785; TP1A.220624.014)',
      ).localized,
      'Xiaomi M2101K7BNY',
    );

    expect(
      const UserAgent(
        'Tapopa/0.1.0-alpha.8 (iOS 16.5.1; iPhone15,3; Darwin Kernel Version 22.5.0: Thu Jun  8 17:15:47 PDT 2023; root:xnu-8796.122.5~1/RELEASE_ARM64_T8120; ARM64E; E56728D4-9546-4236-8748-CA98599E452B)',
      ).localized,
      'iPhone 14 Pro Max',
    );

    expect(
      const UserAgent(
        'Tapopa/0.1.0-alpha.8 (iPadOS 17.4.1; iPad8,11; Darwin Kernel Version 23.4.0: Fri Mar  8 23:30:38 PST 2024; root:xnu-10063.102.14~67/RELEASE_ARM64_T8020; ARM64E; E6215ED0-2E82-49A9-A656-5C5CB5025D06)',
      ).localized,
      'iPad Pro (12.9-inch) (4th generation)',
    );

    expect(
      const UserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      ).localized,
      'Chrome 124',
    );

    expect(
      const UserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0',
      ).localized,
      'Microsoft Edge 124',
    );

    expect(
      const UserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/25.0 Chrome/121.0.0.0 Mobile Safari/537.36',
      ).localized,
      'Samsung Browser 25.0',
    );

    expect(
      const UserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Version/17.4.1 Safari/537.36',
      ).localized,
      'Safari 17.4.1',
    );

    const String partial =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)';

    expect(const UserAgent(partial).localized, partial);

    expect(
      const UserAgent(
        'Tapopa/0.1.0-alpha.8 (fqw fgq bad 12312312312312',
      ).localized,
      'fqw fgq bad 12312312312312',
    );

    expect(
      const UserAgent('Tapopa/0.1.0-alpha.8').localized,
      'Tapopa/0.1.0-alpha.8',
    );

    expect(
      const UserAgent(
        'Tapopa/1.5.2 (Windows 10 Pro; 21H2; build 19041.1.amd64fre.vb_release.191206-1406; x64; {487C0C09-4B5F-407F-9C26-313F31B79F06})',
      ).localized,
      'Windows 10 Pro',
    );

    expect(
      const UserAgent(
        'Tapopa (Windows 10 Pro; 21H2; build 19041.1.amd64fre.vb_release.191206-1406; x64; {487C0C09-4B5F-407F-9C26-313F31B79F06})',
      ).localized,
      'Windows 10 Pro',
    );

    expect(
      const UserAgent(
        'Tapopa 123 5.6. 123 (Windows 10 Pro; 21H2; build 19041.1.amd64fre.vb_release.191206-1406; x64; {487C0C09-4B5F-407F-9C26-313F31B79F06})',
      ).localized,
      'Windows 10 Pro',
    );

    expect(
      const UserAgent(
        'AppName (Windows 10 Pro; 21H2; build 19041.1.amd64fre.vb_release.191206-1406; x64; {487C0C09-4B5F-407F-9C26-313F31B79F06})',
      ).localized,
      'Windows 10 Pro',
    );

    expect(
      const UserAgent('AppName/0.1.0-alpha.8').localized,
      'AppName/0.1.0-alpha.8',
    );
  });
}

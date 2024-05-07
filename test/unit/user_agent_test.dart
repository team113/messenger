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
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/ui/page/home/page/my_profile/session/controller.dart';

void main() async {
  test('UserAgentExtension returns correct names of `User-Agent` header', () {
    Config.userAgentProduct = 'Gapopa';

    expect(
      const UserAgent(
        'Gapopa/0.1.0-alpha.8 (macOS Version 13.3.1 (Build 22E261) Darwin Kernel Version 22.4.0: Mon Mar  6 20:59:28 PST 2023; root:xnu-8796.101.5 ~3/RELEASE_ARM64_T6000; arm64 Apple M1 Max; device: MacBookPro18,2; E08855EB-C338-5EDC-B046-713AC743BA90)',
      ).deviceName,
      'MacBookPro18,2',
    );

    expect(
      const UserAgent(
        'Gapopa/0.1.0-alpha.8 (macOS Version 13.3.1 (Build 22E261) Darwin Kernel Version 22.4.0: Mon Mar  6 20:59:28 PST 2023; root:xnu-8796.101.5 ~3/RELEASE_ARM64_T6000; arm64; device: MacBookPro18,2; E08855EB-C338-5EDC-B046-713AC743BA90)',
      ).deviceName,
      'MacBookPro18,2',
    );

    expect(
      const UserAgent(
        'Gapopa/0.1.0-alpha.8 (macOS Version 13.3.1 (Build 22E261) Darwin Kernel Version 22.4.0: Mon Mar  6 20:59:28 PST 2023; root:xnu-8796.101.5 ~3/RELEASE_ARM64_T6000; arm64 Apple M1 Max; device: MacBookPro18,2)',
      ).deviceName,
      'MacBookPro18,2',
    );

    expect(
      const UserAgent(
        'Gapopa/0.1.0-alpha.8 (macOS Version 13.3.1 (Build 22E261) Darwin Kernel Version 22.4.0: Mon Mar  6 20:59:28 PST 2023; root:xnu-8796.101.5 ~3/RELEASE_ARM64_T6000; arm64; device: MacBookPro18,2)',
      ).deviceName,
      'MacBookPro18,2',
    );

    expect(
      const UserAgent(
        'Gapopa/0.1.0-alpha.8 (Windows 10 Pro; (build 19041.1.amd64fre.vb_release.191206-1406); 21H2; x64; {487C0C09-4B5F-407F-9C26-313F31B79F06})',
      ).deviceName,
      'Windows 10 Pro',
    );

    expect(
      const UserAgent(
        'Gapopa/0.1.0-alpha.8 (Ubuntu 22.04; LTS 5.15.0-48-generic; aarch64; 3787c48ab74047b28638ef2ddc97be6c)',
      ).deviceName,
      'Ubuntu 22.04',
    );

    expect(
      const UserAgent(
        'Gapopa/0.1.0-alpha.8 (Android 13 V14.0.1.0.TKLRUXM (build Redmi/rosemary_ru/rosemary:13/TP1A.220624.014/V14.0.1.0.TKLRUXM:user/release-keys); SDK 33; aarch64 mt6785; device: Xiaomi M2101K7BNY; TP1A.220624.014)',
      ).deviceName,
      'Xiaomi M2101K7BNY',
    );

    expect(
      const UserAgent(
        'Gapopa/0.1.0-alpha.8 (iOS 16.5.1 Darwin Kernel Version 22.5.0: Thu Jun  8 17:15:47 PDT 2023; root:xnu-8796.122.5~1/RELEASE_ARM64_T8120; ARM64E; device: iPhone15,3; E56728D4-9546-4236-8748-CA98599E452B)',
      ).deviceName,
      'iPhone15,3',
    );

    expect(
      const UserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      ).deviceName,
      'Chrome 124',
    );

    expect(
      const UserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0',
      ).deviceName,
      'Microsoft Edge 124',
    );

    expect(
      const UserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/25.0 Chrome/121.0.0.0 Mobile Safari/537.36',
      ).deviceName,
      'Samsung Browser 25.0',
    );

    expect(
      const UserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Version/18.5 Safari/537.36',
      ).deviceName,
      'Safari 18.5',
    );

    const String partial =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)';

    expect(const UserAgent(partial).deviceName, partial);
  });
}

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

import 'package:dio/dio.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/pubspec.g.dart';
import 'package:messenger/util/platform_utils.dart';

import '../world/custom_world.dart';

/// Mocks the [Dio] to response to `/appcast.xml` request with a hardcoded
/// Sparkle Appcast XML.
///
/// Examples:
/// - Given appcast is available
final StepDefinitionGeneric haveInternetWithDelay = given<CustomWorld>(
  'appcast is available',
  (context) async {
    PlatformUtils.client?.interceptors
        .removeWhere((e) => e is InterceptorsWrapper);

    (await PlatformUtils.dio).interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.endsWith('appcast.xml')) {
            return handler.resolve(
              Response(
                requestOptions: options,
                data: '''
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <item>
      <title>v${Pubspec.ref}+1</title>
      <description>Description</description>
      <pubDate>Fri, 26 Apr 2024 09:43:16 +0000</pubDate>
      <enclosure sparkle:os="macos" url="messenger-macos.zip" />
      <enclosure sparkle:os="windows" url="messenger-windows.zip" />
      <enclosure sparkle:os="linux" url="messenger-linux.zip" />
      <enclosure sparkle:os="android" url="messenger-android.zip" />
      <enclosure sparkle:os="ios" url="messenger-ios.zip" />
    </item>
  </channel>
</rss>
''',
              ),
            );
          }

          return handler.next(options);
        },
      ),
    );
  },
);

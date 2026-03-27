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

import 'package:gherkin/gherkin.dart';

/// Possible Appcast Sparkle XML version.
enum AppcastVersion { current, newer, critical }

/// [CustomParameter] representing an [AppcastVersion].
class AppcastVersionParameter extends CustomParameter<AppcastVersion> {
  AppcastVersionParameter()
    : super(
        'version',
        RegExp(
          '(${AppcastVersion.values.map((e) => e.name).join('|')})',
          caseSensitive: false,
        ),
        (c) => AppcastVersion.values.firstWhere((e) => e.name == c),
      );
}

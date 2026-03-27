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

// ignore_for_file: constant_identifier_names

import 'package:gherkin/gherkin.dart';

/// [Credentials] available in a [CredentialsParameter].
enum TestCredential { num, login, directLink }

/// [CustomParameter] of [TestCredential]s representing [Credentials] of a
/// [CustomUser].
class CredentialsParameter extends CustomParameter<TestCredential> {
  CredentialsParameter()
    : super('credential', RegExp('(num|login|direct link)'), (c) {
        switch (c) {
          case 'direct link':
            return TestCredential.directLink;

          default:
            return TestCredential.values.firstWhere((e) => e.name == c);
        }
      });
}

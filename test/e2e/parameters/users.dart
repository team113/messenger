// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

/// [User]s available in a [UsersParameter].
enum TestUser {
  Alice,
  Bob,
  Charlie,
}

/// [CustomParameter] of [TestUser]s representing an [User] of a test.
class UsersParameter extends CustomParameter<TestUser> {
  UsersParameter()
      : super(
          'user',
          RegExp(
            '(${TestUser.values.map((e) => e.name).join('|')})',
            caseSensitive: true,
          ),
          (c) => TestUser.values.firstWhere((e) => e.name == c),
        );
}

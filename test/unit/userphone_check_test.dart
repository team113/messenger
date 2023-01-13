// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/domain/model/user.dart';

void main() async {
  test('Parsing UserPhone successfully', () {
    expect(UserPhone('+5071234123'), UserPhone('+5071234123'));
    expect(UserPhone('+507(123)41-23'), UserPhone('+507(123)41-23'));
    expect(UserPhone('+507 (123)41-23'), UserPhone('+507 (123)41-23'));
    expect(UserPhone('+25512 123 1234'), UserPhone('+25512 123 1234'));
    expect(UserPhone('+255 12 123 1234'), UserPhone('+255 12 123 1234'));
  });

  test('Parsing UserPhone throws FormatException', () {
    expect(() => UserPhone('some number'), throwsA(isA<FormatException>()));
    expect(() => UserPhone('+123456'), throwsA(isA<FormatException>()));
    expect(() => UserPhone('+507123a4123'), throwsA(isA<FormatException>()));
    expect(() => UserPhone('5071234123'), throwsA(isA<FormatException>()));
    expect(
      () => UserPhone('+1234567890123456789'),
      throwsA(isA<FormatException>()),
    );
  });
}

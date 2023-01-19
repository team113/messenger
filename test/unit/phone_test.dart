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
    UserPhone('+5071234123');
    UserPhone('+507(123)41-23');
    UserPhone('+507 (123)41-23');
    UserPhone('+507 (123) 41-23');
    UserPhone('+25512 123 1234');
    UserPhone('+255 12 123 1234');
    UserPhone('+672 3 23 123');
    UserPhone('+3197010282550');
    UserPhone('+61 412 345 678');
    UserPhone('+1 767 614 1234');
    UserPhone('+20-2-1234-1234');
    UserPhone('+372 123 1234');
    UserPhone('+268 12 34 5678');
    UserPhone('+500 12345');
    UserPhone('+679 333 1234');
    UserPhone('+33 512 34 56 78');
    UserPhone('+299 12 34 56');
    UserPhone('+91 7503907302');
    UserPhone('+91 93123-12345');
    UserPhone('+47-79 1234 1234');
    UserPhone('+383 455-5526-0');
    UserPhone('+213 24 81 36 22');
    UserPhone('+994 12 4406736');
    UserPhone('+242-326-4956');
    UserPhone('+(12) 7791-5162');
    UserPhone('+13063771789');
    UserPhone('+53 7867 9109');
    UserPhone('+722 215-9977');
    UserPhone('+373(22)75-11-28');
    UserPhone('+886-2-27525321');
    UserPhone('+4131 356 83 87');
    UserPhone('+420 731 997 314');
    UserPhone('+66 076 261 765');
    UserPhone('+9671245509');
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

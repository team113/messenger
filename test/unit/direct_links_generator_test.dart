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

void main() {
  group('ChatDirectLinkSlug', () {
    test('Should generate a slug of given length', () {
      final slug = ChatDirectLinkSlug.generate(10);
      expect(slug.val.length, equals(10));
    });

    test('Should generate a slug with valid characters', () {
      final slug = ChatDirectLinkSlug.generate(10);
      final validChars = RegExp(r'^[A-Za-z0-9_-]+$');
      expect(validChars.hasMatch(slug.val), isTrue);
    });

    test('Should not end with a hyphen', () {
      final slug = ChatDirectLinkSlug.generate();
      expect(slug.val.endsWith('-'), isFalse);
    });
  });
}

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
import 'package:messenger/ui/widget/markdown.dart';

/// Unit tests for [MarkdownSelectionParser].
void main() {
  group('markdownSelectedTextFromFullText Tests', () {
    test('Returns empty string when selectedText is empty', () {
      final result = ''.reconstructFrom('Hello World');

      expect(result, equals(''));
    });

    test('Returns selectedText directly when exact match exists', () {
      final result = 'is amazing'.reconstructFrom('Flutter is amazing');

      expect(result, equals('is amazing'));
    });

    test('Strips markdown control characters during normalization', () {
      final result = 'This is a Header with link and code'.reconstructFrom(
        'This is a #Header with [link] and `code`',
      );

      expect(result, equals('This is a Header with link and code'));
    });

    test('Removes non-ASCII characters during normalization', () {
      final result = 'Hello Rocket 🚀'.reconstructFrom('Hello Rocket 🚀');

      expect(result.trim(), equals('Hello Rocket'));
    });

    test('Trims invalid prefix and suffix during reconstruction', () {
      final result = 'XYZquick brown ABC'.reconstructFrom(
        'The quick brown fox',
      );

      expect(result, contains('quick brown'));
      expect(result, isNot(contains('XYZ')));
      expect(result, isNot(contains('ABC')));
    });

    test('Handles repeated substring edge cases correctly', () {
      final result = 'repeat repeat'.reconstructFrom('repeat repeat repeat');

      expect(result, isNotEmpty);
      expect(result, contains('repeat repeat'));
    });
  });
}

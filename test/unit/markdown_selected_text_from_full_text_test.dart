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
import 'package:messenger/ui/page/work/page/freelance/helper_function/markdown_selected_text_from_full_text.dart';

/// Unit tests for [markdownSelectedTextFromFullText].
///
/// These tests verify correct reconstruction of selected markdown text,
/// including normalization behavior, edge cases, and complex prefix/suffix
/// matching logic.
///
/// The test suite ensures:
/// - Empty selections return an empty string.
/// - Exact matches are returned without modification.
/// - Markdown control characters are stripped correctly.
/// - Non-ASCII characters are removed according to normalization rules.
/// - Prefix/suffix trimming logic works for partial selections.
/// - Repeated text edge cases are handled safely.
void main() {
  group('markdownSelectedTextFromFullText Tests', () {
    /// Verifies that an empty [selectedText] returns an empty result.
    ///
    /// This ensures safe behavior when no text is selected.
    test('Returns empty string when selectedText is empty', () {
      final result = markdownSelectedTextFromFullText(
        fullText: 'Hello World',
        selectedText: '',
      );

      expect(result, equals(''));
    });

    /// Ensures that when [selectedText] already exists exactly
    /// within [fullText], no reconstruction is performed.
    test('Returns selectedText directly when exact match exists', () {
      final result = markdownSelectedTextFromFullText(
        fullText: 'Flutter is amazing',
        selectedText: 'is amazing',
      );

      expect(result, equals('is amazing'));
    });

    /// Ensures markdown control characters (`#`, `[`, `]`, `` ` ``)
    /// are removed before matching.
    test('Strips markdown control characters during normalization', () {
      final result = markdownSelectedTextFromFullText(
        fullText: 'This is a #Header with [link] and `code`',
        selectedText: 'This is a Header with link and code',
      );

      expect(result, equals('This is a Header with link and code'));
    });

    /// Verifies removal of unsupported non-ASCII characters
    /// such as emojis according to the defined RegExp.
    test('Removes non-ASCII characters during normalization', () {
      final result = markdownSelectedTextFromFullText(
        fullText: 'Hello Rocket 🚀',
        selectedText: 'Hello Rocket 🚀',
      );

      expect(result.trim(), equals('Hello Rocket'));
    });

    /// Tests prefix and suffix trimming logic when the selection
    /// contains extra characters not present in [fullText].
    ///
    /// The algorithm should identify the longest valid matching
    /// substring and discard invalid surrounding characters.
    test('Trims invalid prefix and suffix during reconstruction', () {
      final result = markdownSelectedTextFromFullText(
        fullText: 'The quick brown fox',
        selectedText: 'XYZquick brown ABC',
      );

      expect(result, contains('quick brown'));
      expect(result, isNot(contains('XYZ')));
      expect(result, isNot(contains('ABC')));
    });

    /// Ensures stability when matching repeated segments within
    /// the full text.
    ///
    /// This triggers the internal branch that refines suffix
    /// matching when multiple occurrences are detected.
    test('Handles repeated substring edge cases correctly', () {
      final result = markdownSelectedTextFromFullText(
        fullText: 'repeat repeat repeat',
        selectedText: 'repeat repeat',
      );

      expect(result, isNotEmpty);
      expect(result, contains('repeat repeat'));
    });
  });
}

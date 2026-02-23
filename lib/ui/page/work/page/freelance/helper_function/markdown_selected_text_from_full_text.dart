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

import 'package:gpt_markdown/gpt_markdown.dart';

/// Reconstructs the selected markdown text with its original line breaks.
///
/// Flutter's selection system returns flattened plain text without real
/// newline characters (`\n`). This function restores the original formatting
/// by matching [selectedText] against [fullText] and reinserting newline
/// characters that were removed during selection.
///
/// The function:
/// - Preserves original `\n` and `\r` characters from [fullText].
/// - Matches characters in order.
/// - Strips unsupported markdown control characters before comparison.
///
/// Returns an empty string if:
/// - [selectedText] is empty
/// - No valid match can be reconstructed
///
/// Assumes that [selectedText] appears in [fullText] in the same order.
String markdownSelectedTextFromFullText({
  required String fullText,
  required String selectedText,
}) {
  // Normalize input by removing markdown control characters
  // and unsupported ASCII characters to ensure consistent matching.
  fullText = fullText
      .replaceAll(RegExp(r'[#\[\]`]|[^\x20-\x7E\n\r]'), '');

  selectedText = selectedText.replaceAll(RegExp(r'[#]|[^\x20-\x7E\n\r]'), '');

  if (selectedText.isEmpty) {
    return '';
  }

  // If the full text already contains the selected text exactly,
  // no reconstruction is needed.
  if (fullText.contains(selectedText)) {
    return selectedText;
  }

  String reconstructedText = '';

  // ---------------------------------------------------------------------------
  // STEP 1: Find the longest matching prefix of selectedText inside fullText.
  // ---------------------------------------------------------------------------
  String prefixMatch = '';

  for (int i = 0; i < selectedText.length; i++) {
    prefixMatch += selectedText[i];

    if (!fullText.contains(prefixMatch)) {
      // Remove the last character that broke the match.
      prefixMatch = prefixMatch.substring(0, prefixMatch.length - 1);
      break;
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Find the longest matching suffix of selectedText inside fullText.
  // ---------------------------------------------------------------------------
  String suffixMatch = '';

  for (int i = selectedText.length - 1; i >= 0; i--) {
    suffixMatch = selectedText[i] + suffixMatch;

    if (!fullText.contains(suffixMatch)) {
      // Remove the first character that broke the match.
      suffixMatch = suffixMatch.substring(1, suffixMatch.length);
      break;
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Remove everything before the prefix match.
  // ---------------------------------------------------------------------------
  final List<String> prefixSplit = fullText.split(prefixMatch);
  prefixSplit.removeAt(0);

  reconstructedText = prefixMatch + prefixSplit.join(prefixMatch);

  // ---------------------------------------------------------------------------
  // STEP 4: Remove everything after the suffix match.
  // Handles edge cases where suffix appears multiple times.
  // ---------------------------------------------------------------------------
  final List<String> suffixSplit = reconstructedText.split(suffixMatch);

  if (suffixSplit.length > 2) {
    // If suffix appears multiple times, refine the match
    // by recalculating a shorter valid suffix.
    final String selectedWithoutSuffix = selectedText.substring(
      0,
      selectedText.length - suffixMatch.length,
    );

    String refinedSuffix = '';

    for (int i = selectedWithoutSuffix.length - 1; i >= 0; i--) {
      refinedSuffix = selectedWithoutSuffix[i] + refinedSuffix;

      if (!fullText.contains(refinedSuffix)) {
        refinedSuffix = refinedSuffix.substring(1, refinedSuffix.length);
        break;
      }
    }

    final List<String> refinedSplit = reconstructedText.split(refinedSuffix);

    refinedSplit.removeLast();

    reconstructedText = refinedSplit.join(refinedSuffix) + refinedSuffix;
  } else {
    suffixSplit.removeLast();

    reconstructedText = suffixSplit.join(suffixMatch) + suffixMatch;
  }

  return reconstructedText;
}

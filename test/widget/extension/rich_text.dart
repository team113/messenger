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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TODO: Remove and use [find.text] when flutter/flutter#124859 is fixed:
//       https://github.com/flutter/flutter/issues/124859
/// Extension adding finder for a [RichText].
extension RichTextExtension on CommonFinders {
  /// Returns a [Finder] matching a [RichText] with the provided [text], if any.
  Finder richText(String text, {bool skipOffstage = true}) {
    return find.byWidgetPredicate(
      (Widget widget) =>
          widget is RichText &&
          widget.text.toPlainText(includePlaceholders: false) == text,
      skipOffstage: skipOffstage,
    );
  }
}

// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

// TODO: Remove and use [FontFeature.tabularFigures] when flutter/flutter#118485
//       is fixed:
//       https://github.com/flutter/flutter/issues/118485
import 'package:flutter/widgets.dart';

/// Extension adding a fixed-length digits [Text] transformer.
extension FixedDigitsExtension on Text {
  /// [RegExp] detecting numbers.
  static final RegExp _regex = RegExp(r'\d');

  /// Returns a [Text] guaranteed to have fixed width of digits in it.
  Widget fixedDigits() {
    Text copyWith(String string) {
      return Text(
        string,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }

    return Stack(
      children: [
        Opacity(opacity: 0, child: copyWith(data!.replaceAll(_regex, '0'))),
        copyWith(data!),
      ],
    );
  }
}

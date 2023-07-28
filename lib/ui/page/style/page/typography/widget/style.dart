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

import '/themes.dart';

/// [Column] displaying the provided [TextStyle] in a descriptive way.
class FontStyle extends StatelessWidget {
  const FontStyle(this.style, {super.key, this.inverted = false});

  /// [TextStyle] along with its title to display.
  final (TextStyle, String) style;

  /// Indicator whether this [FontStyle] should have its colors
  /// inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    // Returns a [Row] spacing its [title] and [subtitle] with a [Divider].
    Widget cell(String title, String subtitle) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Text(title),
            Expanded(
              child: Divider(
                indent: 8,
                endIndent: 8,
                color: inverted
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFFE8E8E8),
              ),
            ),
            Text(subtitle),
          ],
        ),
      );
    }

    return SizedBox(
      width: 190,
      child: DefaultTextStyle(
        style: fonts.bodySmall!.copyWith(
          color: inverted ? const Color(0xFFFFFFFF) : const Color(0xFF888888),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Text(
                style.$2,
                style: style.$1.copyWith(
                  color: inverted
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF000000),
                ),
              ),
            ),
            const SizedBox(height: 8),
            cell('Size', style.$1.fontSize.toString()),
            cell('Weight', style.$1.fontWeight!.value.toString()),
            cell('Style', style.$1.fontWeight?.name ?? ''),
            cell('Color', style.$1.color!.toHex()),
            cell('Spacing', '${style.$1.letterSpacing ?? 0} %'),
          ],
        ),
      ),
    );
  }
}

/// Extension adding conversion of [FontWeight] to its name.
extension on FontWeight {
  /// Returns this [FontWeight] localized as a [String].
  String get name => switch (value) {
        100 => 'Thin',
        200 => 'Extra-light',
        300 => 'Light',
        400 => 'Regular',
        500 => 'Medium',
        600 => 'Semi-bold',
        700 => 'Bold',
        800 => 'Extra-bold',
        900 => 'Black',
        _ => 'Regular',
      };
}

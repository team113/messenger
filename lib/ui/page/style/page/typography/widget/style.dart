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

/// [Container] which represents [Text] with a specific [style].
class FontStyle extends StatelessWidget {
  const FontStyle(
    this.inverted, {
    super.key,
    this.style,
    this.title,
  });

  /// Indicator whether this [FontStyle] should have its colors
  /// inverted.
  final bool inverted;

  /// Label of this [FontStyle].
  final String? title;

  /// [TextStyle] defining the font style for this [FontStyle].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    // Returns a [Row] spacing its [title] and [subtitle] with a [Divider].
    Widget cell(String title, String subtitle) {
      return Row(
        children: [
          Text(title),
          Expanded(
            child: Divider(
              indent: 10,
              endIndent: 10,
              color:
                  inverted ? const Color(0xFFFFFFFF) : const Color(0xFFE8E8E8),
            ),
          ),
          Text(subtitle),
        ],
      );
    }

    return SizedBox(
      width: 210,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (title != null)
            Center(
              child: Text(
                title!,
                style: style!.copyWith(
                  color: inverted
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF000000),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Divider(
            color: inverted ? const Color(0xFFFFFFFF) : const Color(0xFFE8E8E8),
            indent: 25,
            endIndent: 25,
          ),
          const SizedBox(height: 8),
          DefaultTextStyle(
            style: fonts.bodySmall!.copyWith(
              color:
                  inverted ? const Color(0xFFFFFFFF) : const Color(0xFF888888),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  cell('Size', style!.fontSize.toString()),
                  const SizedBox(height: 10),
                  cell('Weight', style!.fontWeight!.value.toString()),
                  const SizedBox(height: 10),
                  cell('Style', style!.fontWeight?.name ?? ''),
                  const SizedBox(height: 10),
                  cell('Color', style!.color!.toHex()),
                  const SizedBox(height: 10),
                  cell(
                    'Spacing',
                    style!.letterSpacing == null
                        ? '0 %'
                        : '${style!.letterSpacing} %',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
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

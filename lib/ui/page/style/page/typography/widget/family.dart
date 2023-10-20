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

/// [FontWeight] visual representation.
class FontFamily extends StatelessWidget {
  const FontFamily(
    this.family, {
    super.key,
    this.inverted = false,
    this.dense = false,
  });

  /// [FontWeight] along with its title to display.
  final (FontWeight, String) family;

  /// Indicator whether this [FontFamily] should have its colors
  /// inverted.
  final bool inverted;

  /// Indicator whether this [FontFamily] should be dense, meaning no
  /// [Padding]s.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return DefaultTextStyle(
      style: inverted
          ? style.fonts.largest.bold.onBackground
          : style.fonts.largest.bold.onPrimary.copyWith(fontWeight: family.$1),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: dense ? 0 : 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Flexible(
              child: Text(
                'ABCDEFGHIJKLMNOPQRSTUVWXYZ\n'
                'abcdefghijklmnopqrstuvwxyz\n'
                '1234567890 _-–—.,:;!?()[]{}|©=+£€\$&%№«»“”˚*',
              ),
            ),
            Text(family.$2),
          ],
        ),
      ),
    );
  }
}

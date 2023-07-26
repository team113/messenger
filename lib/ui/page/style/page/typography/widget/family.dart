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
  const FontFamily(this.family, {super.key, this.inverted = false});

  /// [FontWeight] along with its title to display.
  final (FontWeight, String) family;

  /// Indicator whether this [FontFamily] should have its colors
  /// inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return DefaultTextStyle(
      style: fonts.displayLarge!.copyWith(
        color: inverted ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
        fontWeight: family.$1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ABCDEFGHIJKLMNOPQRSTUVWXYZ\n'
              'abcdefghijklmnopqrstuvwxyz\n'
              '1234567890 _-–—.,:;!?()[]{}|©=+£€\$&%№«»“”˚*',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  family.$2,
                  style: fonts.displayLarge!.copyWith(
                    color: const Color(0xFFF5F5F5),
                    fontSize: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

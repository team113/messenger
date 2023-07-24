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

/// [Column] of all characters in a specific font family.
class FontFamily extends StatelessWidget {
  const FontFamily(
    this.inverted, {
    super.key,
    this.fontWeight,
    this.label,
  });

  /// Indicator whether this [FontFamily] should have its colors
  /// inverted.
  final bool inverted;

  /// Label of this [FontFamily].
  final String? label;

  /// [FontWeight] of this [FontFamily].
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return DefaultTextStyle(
      style: fonts.displayLarge!.copyWith(
        color: inverted ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
        fontWeight: fontWeight,
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
            const SizedBox(height: 40),
            const Text('abcdefghijklmnopqrstuvwxyz'),
            const SizedBox(height: 40),
            const Row(
              children: [
                Flexible(child: Text('1234567890', softWrap: true)),
                SizedBox(width: 50),
                Flexible(
                  child: Text(
                    '_-–—.,:;!?()[]{}|©=+£€\$&%№«»“”˚*',
                    softWrap: true,
                  ),
                ),
              ],
            ),
            if (label != null)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    label!,
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

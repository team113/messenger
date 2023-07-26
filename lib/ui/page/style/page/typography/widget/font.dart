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

/// [Row] displaying the provided [TextStyle] in a compact way.
class FontWidget extends StatelessWidget {
  const FontWidget(
    this.style, {
    super.key,
    this.inverted = false,
    this.dense = false,
  });

  /// [TextStyle] along with its title to display.
  final (TextStyle, String) style;

  /// Indicator whether this [FontWidget] should have its colors inverted.
  final bool inverted;

  /// Indicator whether this [FontWidget] should be dense, meaning no
  /// [Padding]s.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Row(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
          child: SizedBox(width: dense ? 0 : 16),
        ),
        Text(
          '${style.$1.fontSize} pt, w${style.$1.fontWeight?.value}',
          style: fonts.titleMedium?.copyWith(
            color: inverted ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
            alignment: dense ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              style.$2,
              style: style.$1.copyWith(
                color: inverted
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF000000),
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
          child: SizedBox(width: dense ? 0 : 16),
        ),
      ],
    );
  }
}

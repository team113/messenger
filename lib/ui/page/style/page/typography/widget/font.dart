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
import '/util/platform_utils.dart';

/// Custom-styled [Text] with information.
class FontWidget extends StatelessWidget {
  const FontWidget(
    this.inverted, {
    super.key,
    this.title,
    this.style,
  });

  /// Indicator whether this [FontWidget] should have its colors inverted.
  final bool inverted;

  /// Title of this [FontWidget].
  final String? title;

  /// [TextStyle] of this [FontWidget].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.isNarrow ? 5 : 15,
        vertical: 5,
      ),
      child: Row(
        mainAxisAlignment: context.isNarrow
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '${style!.fontSize} pt, w${style!.fontWeight?.value}',
              style: fonts.titleMedium?.copyWith(
                color: inverted
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF000000),
              ),
            ),
          ),
          if (title != null)
            SizedBox(
              width: 175,
              child: Text(
                title!,
                style: style!.copyWith(
                  color: inverted
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF000000),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

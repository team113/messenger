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

import 'dart:math';

import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [Row] describing visually the provided [font].
class FontRow extends StatelessWidget {
  const FontRow({
    required this.font,
    required this.size,
    required this.weight,
    required this.color,
    super.key,
  });

  /// [TextStyle] to describe.
  final TextStyle font;

  /// Size naming of this [font].
  final String size;

  /// Weight naming of this [font].
  final String weight;

  /// Color naming of this [font].
  final String color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final HSLColor hsl = HSLColor.fromColor(font.color!);

    final Color detailsColor = hsl.lightness > 0.7 || hsl.alpha < 0.4
        ? const Color(0xFFC4C4C4)
        : const Color(0xFF888888);

    final Color background = hsl.lightness > 0.7 || hsl.alpha < 0.4
        ? const Color(0xFF888888)
        : const Color(0xFFFFFFFF);

    return Container(
      color: background,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: WidgetButton(
                onPressed: () async {
                  PlatformUtils.copy(text: '$size.$weight.$color');
                  MessagePopup.success('Name is copied');
                },
                child: Text(
                  '$size.$weight.$color  ',
                  style: font,
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              0,
              0,
              max(0, ((font.fontSize! - 10) / (27 - 10)) * 5),
            ),
            child: Row(
              children: [
                Text(
                  'w${font.fontWeight?.value}, ',
                  style: style.fonts.smaller.regular.onBackground.copyWith(
                    color: detailsColor,
                  ),
                ),
                WidgetButton(
                  onPressed: () async {
                    PlatformUtils.copy(
                      text: font.color!.toHex(withAlpha: false),
                    );
                    MessagePopup.success('Hash is copied');
                  },
                  child: Text(
                    font.color!.toHex(withAlpha: false),
                    style: style.fonts.smaller.regular.onBackground.copyWith(
                      color: detailsColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

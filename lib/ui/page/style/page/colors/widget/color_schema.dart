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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/themes.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [Column] of the provided [colors] representing a [Color] scheme.
class ColorSchemaWidget extends StatelessWidget {
  const ColorSchemaWidget(this.colors, {super.key, this.inverted = false});

  /// Records of [Color]s and its descriptions to display.
  final Iterable<(Color, String?)> colors;

  /// Indicator whether the background of this [ColorSchemaWidget] should be
  /// inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: inverted ? style.colors.onBackground : style.colors.onPrimary,
      ),
      child: Table(
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(),
          1: IntrinsicColumnWidth(),
          2: IntrinsicColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          ...colors.map((e) {
            final HSLColor hsl = HSLColor.fromColor(e.$1);
            final Color text =
                (!inverted || hsl.alpha > 0.7) &&
                    (hsl.lightness > 0.7 || hsl.alpha < 0.4)
                ? style.colors.onBackground
                : style.colors.onPrimary;
            final TextStyle textStyle = style.fonts.small.regular.onBackground
                .copyWith(color: text);
            final double paddings = context.isNarrow ? 4 : 128;

            return TableRow(
              decoration: BoxDecoration(color: e.$1),
              children: [
                TableCell(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(paddings, 16, 0, 16),
                    alignment: Alignment.centerLeft,
                    child: WidgetButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: e.$2 ?? ''));
                        MessagePopup.success('Name is copied');
                      },
                      child: Text(e.$2 ?? '', style: textStyle),
                    ),
                  ),
                ),
                TableCell(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.fromLTRB(
                      8,
                      0,
                      context.isNarrow ? 8 : 32,
                      0,
                    ),
                    child: WidgetButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: e.$1.toHex()));
                        MessagePopup.success('Color is copied');
                      },
                      child: Text(e.$1.toHex(), style: textStyle),
                    ),
                  ),
                ),
                TableCell(
                  child: Container(
                    padding: EdgeInsets.only(right: paddings),
                    alignment: Alignment.center,
                    child: WidgetButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: e.$1.toHex(withAlpha: false)),
                        );
                        MessagePopup.success('HEX is copied');
                      },
                      child: Text(
                        '${(e.$1.a * 100).round()}% ${e.$1.toHex(withAlpha: false)}',
                        style: textStyle,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

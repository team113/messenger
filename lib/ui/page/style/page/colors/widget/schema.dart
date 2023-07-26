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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/themes.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';

/// [Column] of the provided [colors] representing a [Color] scheme.
class ColorSchemaWidget extends StatelessWidget {
  const ColorSchemaWidget(this.colors, {super.key, this.inverted = false});

  /// Records of [Color]s and its descriptions to display.
  final Iterable<(Color, String)> colors;

  /// Indicator whether the background of this [ColorSchemaWidget] should be
  /// inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: inverted ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
      ),
      child: Column(
        children: colors.mapIndexed((i, e) {
          final HSLColor hsl = HSLColor.fromColor(e.$1);
          final Color text = hsl.lightness > 0.7 || hsl.alpha < 0.4
              ? const Color(0xFF000000)
              : const Color(0xFFFFFFFF);
          final TextStyle style = fonts.bodySmall!.copyWith(color: text);

          return Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: e.$1,
              borderRadius: BorderRadius.only(
                topLeft: i == 0 ? const Radius.circular(16) : Radius.zero,
                topRight: i == 0 ? const Radius.circular(16) : Radius.zero,
                bottomLeft: i == colors.length - 1
                    ? const Radius.circular(16)
                    : Radius.zero,
                bottomRight: i == colors.length - 1
                    ? const Radius.circular(16)
                    : Radius.zero,
              ),
            ),
            child: Center(
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  WidgetButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: e.$2));
                      MessagePopup.success('Technical name is copied');
                    },
                    child: Text(e.$2, style: style),
                  ),
                  const Spacer(),
                  WidgetButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: e.$1.toHex()));
                      MessagePopup.success('Hash is copied');
                    },
                    child: Text(e.$1.toHex(), style: style),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

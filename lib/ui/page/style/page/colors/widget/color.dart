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

/// Stylized [Container] describing the provided [color].
class ColorWidget extends StatelessWidget {
  const ColorWidget(
    this.color, {
    super.key,
    this.inverted = false,
    this.subtitle,
    this.hint,
  });

  /// Indicator whether this [ColorWidget] should have its font colors inverted.
  final bool inverted;

  /// [Color] to display.
  final Color color;

  /// Optional subtitle, displayed under the [color].
  final String? subtitle;

  /// Optional hint, displayed as a hint above the [color].
  final String? hint;

  /// Dimensions of this [ColorWidget] to take.
  ///
  /// Note, that height is only about the [color] box, and doesn't account the
  /// [hint] and [subtitle], thus actually may be higher.
  static const double size = 120;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              WidgetButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: color.toHex()));
                  MessagePopup.success('Hash is copied');
                },
                child: Text(
                  color.toHex(),
                  textAlign: TextAlign.start,
                  style: inverted
                      ? style.fonts.small.regular.onBackground
                      : style.fonts.small.regular.onPrimary,
                ),
              ),
              const Spacer(),
              if (hint != null)
                Tooltip(
                  message: hint,
                  child: Icon(
                    Icons.info_outline,
                    size: 13,
                    color: inverted
                        ? style.colors.onBackground
                        : style.colors.onPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Flexible(
              child: WidgetButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: subtitle!));
                  MessagePopup.success('Technical name is copied');
                },
                child: Text(
                  subtitle!,
                  textAlign: TextAlign.left,
                  style: inverted
                      ? style.fonts.smaller.regular.onBackground
                      : style.fonts.smaller.regular.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

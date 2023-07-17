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
import 'package:flutter/services.dart';

import '/themes.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';

/// Stylized [Container] of the provided [color].
class ColorWidget extends StatelessWidget {
  const ColorWidget(
    this.isDarkMode,
    this.color, {
    super.key,
    this.title,
    this.subtitle,
  });

  /// Indicator whether the dark mode is enabled or not.
  final bool isDarkMode;

  /// Color to display.
  final Color color;

  /// Optional title of this [ColorWidget].
  final String? title;

  /// Optional subtitle of this [ColorWidget].
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Row(
            children: [
              const SizedBox(width: 17),
              Text(
                color.toHex(),
                textAlign: TextAlign.start,
                style: fonts.bodySmall!.copyWith(
                  color: isDarkMode
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF000000),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: subtitle ?? '',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: WidgetButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: color.toHex()));
                MessagePopup.success('Copied');
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Row(
            children: [
              const SizedBox(width: 17),
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    textAlign: TextAlign.left,
                    style: fonts.labelSmall!.copyWith(
                      color: isDarkMode
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF000000),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

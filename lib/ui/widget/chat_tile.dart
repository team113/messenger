// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import '/ui/page/home/tab/chats/widget/hovered_ink.dart';

/// Fixed-height chat tile.
class ChatTile extends StatelessWidget {
  const ChatTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.style,
    this.selected = false,
    this.onTap,
    this.height = 94,
  }) : super(key: key);

  /// Widget to display before the title.
  final Widget? leading;

  /// Primary content of the chat tile.
  final Widget? title;

  /// Additional content displayed below the title.
  final Widget? subtitle;

  /// Widget to display after the title.
  final Widget? trailing;

  /// Chat tile styles.
  final Style? style;

  /// Indicator whether chat selection for applying certain styles.
  final bool selected;

  /// Callback, called when the chat tile is tapped.
  final void Function()? onTap;

  /// Fixed tile height.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: InkWellWithHover(
          selectedColor: style?.primaryCardColor,
          unselectedColor: style?.cardColor,
          isSelected: selected,
          hoveredBorder:
              selected ? style?.primaryBorder : style?.hoveredBorderUnselected,
          unhoveredBorder: selected ? style?.primaryBorder : style?.cardBorder,
          borderRadius: style?.cardRadius,
          onTap: onTap,
          unselectedHoverColor: style?.unselectedHoverColor,
          selectedHoverColor: style?.primaryCardColor,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                leading ?? const SizedBox.shrink(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title ?? const SizedBox.shrink(),
                      subtitle ?? const SizedBox.shrink(),
                    ],
                  ),
                ),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

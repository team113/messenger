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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/hovered_ink.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';

class BalanceProviderWidget extends StatelessWidget {
  const BalanceProviderWidget({
    super.key,
    required this.title,
    this.selected = false,
    this.onTap,
    this.leading = const [],
  });

  final String title;
  final bool selected;
  final void Function()? onTap;

  final List<Widget> leading;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return SizedBox(
      height: 94,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: InkWellWithHover(
          selectedColor: style.cardSelectedColor,
          unselectedColor: style.cardColor,
          selected: selected,
          hoveredBorder:
              selected ? style.primaryBorder : style.cardHoveredBorder,
          border: selected ? style.primaryBorder : style.cardBorder,
          borderRadius: style.cardRadius,
          onTap: onTap,
          unselectedHoverColor: style.cardHoveredColor,
          selectedHoverColor: style.cardSelectedColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: [
                const SizedBox(width: 12),
                ...leading.map(
                  (e) => IconTheme(
                    data: IconThemeData(
                      size: 48,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    child: e,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          // ...status,
                        ],
                      ),
                      // ...subtitle,
                    ],
                  ),
                ),
                // ...trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

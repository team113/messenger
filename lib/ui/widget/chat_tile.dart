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
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';

import '/domain/repository/chat.dart';
import '/themes.dart';
import '/ui/page/home/tab/chats/widget/hovered_ink.dart';

/// [Chat] visual representation.
class ChatTile extends StatelessWidget {
  const ChatTile({
    Key? key,
    this.chat,
    this.title = const [],
    this.subtitle = const [],
    this.leading = const [],
    this.trailing = const [],
    this.actions = const [],
    this.style,
    this.selected = false,
    this.onTap,
    this.height = 94,
  }) : super(key: key);

  /// [Chat] this [ChatTile] represents.
  final RxChat? chat;

  /// Optional [Widget]s to display after the [chat]'s title.
  final List<Widget> title;

  /// Optional leading [Widget]s.
  final List<Widget> leading;

  /// Optional trailing [Widget]s.
  final List<Widget> trailing;

  /// Additional content displayed below the title.
  final List<Widget> subtitle;

  /// [ContextMenuRegion.actions] of this [ChatTile].
  final List<ContextMenuButton> actions;

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
    return ContextMenuRegion(
      key: Key('ContextMenuRegion_${chat?.chat.value.id}'),
      preventContextMenu: false,
      actions: actions,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: InkWellWithHover(
            selectedColor: style?.primaryCardColor,
            unselectedColor: style?.cardColor,
            selected: selected,
            hoveredBorder: selected
                ? style?.primaryBorder
                : style?.hoveredBorderUnselected,
            unhoveredBorder:
                selected ? style?.primaryBorder : style?.cardBorder,
            borderRadius: style?.cardRadius,
            onTap: onTap,
            unselectedHoverColor: style?.unselectedHoverColor,
            selectedHoverColor: style?.primaryCardColor,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  AvatarWidget.fromRxChat(chat, radius: 30),
                  const SizedBox(width: 12),
                  ...leading,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat?.title.value ?? 'dot'.l10n * 3,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context).textTheme.headline5,
                              ),
                            ),
                            ...title,
                          ],
                        ),
                        ...subtitle,
                      ],
                    ),
                  ),
                  ...trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

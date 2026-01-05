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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/tab/chats/widget/hovered_ink.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';

/// [Chat] visual representation.
class ChatTile extends StatelessWidget {
  const ChatTile({
    super.key,
    this.chat,
    this.title = const [],
    this.status = const [],
    this.subtitle = const [],
    this.leading = const [],
    this.trailing = const [],
    this.actions = const [],
    this.selected = false,
    this.onTap,
    this.height = 80,
    this.darken = 0,
    this.dimmed = false,
    Widget Function(Widget)? titleBuilder,
    Widget Function(Widget)? avatarBuilder,
    this.enableContextMenu = true,
    this.onForbidden,
  }) : titleBuilder = titleBuilder ?? _defaultBuilder,
       avatarBuilder = avatarBuilder ?? _defaultBuilder;

  /// [Chat] this [ChatTile] represents.
  final RxChat? chat;

  /// Optional [Widget]s to display after the [chat]'s title.
  final List<Widget> title;

  /// Optional [Widget]s to display as a trailing to the [chat]'s title.
  final List<Widget> status;

  /// Optional leading [Widget]s.
  final List<Widget> leading;

  /// Optional trailing [Widget]s.
  final List<Widget> trailing;

  /// Additional content displayed below the [chat]'s title.
  final List<Widget> subtitle;

  /// [ContextMenuRegion.actions] of this [ChatTile].
  final List<ContextMenuItem> actions;

  /// Indicator whether this [ChatTile] is selected.
  final bool selected;

  /// Callback, called when this [ChatTile] is pressed.
  final void Function()? onTap;

  /// Height of this [ChatTile].
  final double height;

  /// Amount of darkening to apply to the background of this [ChatTile].
  final double darken;

  /// Builder for building an [AvatarWidget] this [ChatTile] displays.
  ///
  /// Intended to be used to allow custom [Badge]s, [InkWell]s, etc over the
  /// [AvatarWidget].
  final Widget Function(Widget child) avatarBuilder;

  /// Builder for building the chat title.
  ///
  /// Intended to be used to allow custom modifications over the title.
  final Widget Function(Widget child) titleBuilder;

  /// Indicator whether context menu should be enabled over this [ChatTile].
  final bool enableContextMenu;

  /// Indicator whether this [ChatTile] should have its background a bit dimmed.
  final bool dimmed;

  /// Callback, called when [ChatAvatar] fetching fails with `Forbidden` error.
  final FutureOr<void> Function()? onForbidden;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ContextMenuRegion(
      key: Key('Chat_${chat?.chat.value.id}'),
      preventContextMenu: false,
      actions: actions,
      indicateOpenedMenu: true,
      enabled: enableContextMenu,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 1.5, 0, 1.5),
        child: InkWellWithHover(
          selectedColor: dimmed
              ? style.colors.primary.darken(0.03)
              : style.colors.primary,
          unselectedColor: dimmed
              ? style.colors.onPrimaryOpacity50
              : style.cardColor.darken(darken),
          selected: selected,
          hoveredBorder: selected
              ? style.cardSelectedBorder
              : style.cardHoveredBorder,
          border: selected ? style.cardSelectedBorder : style.cardBorder,
          borderRadius: style.cardRadius,
          onTap: onTap,
          unselectedHoverColor: style.cardHoveredColor,
          selectedHoverColor: dimmed
              ? style.colors.primary.darken(0.03)
              : style.colors.primary,
          folded: chat?.chat.value.favoritePosition != null,
          child: SizedBox(
            height: height,
            child: Padding(
              key: chat?.chat.value.favoritePosition != null
                  ? Key('FavoriteIndicator_${chat?.chat.value.id}')
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  avatarBuilder(
                    AvatarWidget.fromRxChat(
                      chat,
                      radius: switch (height) {
                        >= 65 => AvatarRadius.large,
                        (_) => AvatarRadius.big,
                      },
                      onForbidden: onForbidden,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...leading,
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: titleBuilder(
                                      Obx(() {
                                        return Text(
                                          chat?.title() ?? ('dot'.l10n * 3),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: selected
                                              ? style
                                                    .fonts
                                                    .big
                                                    .regular
                                                    .onPrimary
                                              : style
                                                    .fonts
                                                    .big
                                                    .regular
                                                    .onBackground,
                                        );
                                      }),
                                    ),
                                  ),
                                  ...title,
                                ],
                              ),
                            ),
                            ...status,
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

  /// Returns the [child].
  static Widget _defaultBuilder(Widget child) => child;
}

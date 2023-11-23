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
import 'package:get/get.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/tab/chats/widget/hovered_ink.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';

/// [Chat] visual representation.
class ChatTile extends StatefulWidget {
  const ChatTile({
    super.key,
    this.chat,
    Widget Function(Widget)? titleBuilder,
    this.title = const [],
    this.status = const [],
    this.subtitle = const [],
    this.leading = const [],
    this.trailing = const [],
    this.actions = const [],
    this.active = false,
    this.selected = false,
    this.outlined = false,
    this.onTap,
    this.height = 80,
    this.darken = 0,
    Widget Function(Widget)? avatarBuilder,
    this.enableContextMenu = true,
    this.folded = false,
    this.special = false,
    this.paid = false,
    this.highlight = false,
    this.dimmed = false,
    this.basement,
    this.onBasementPressed,
  })  : titleBuilder = titleBuilder ?? _defaultBuilder,
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

  /// Indicator whether this [ChatTile] is active.
  final bool active;

  final bool outlined;

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

  /// Indicator whether context menu should be enabled over this [ChatTile].
  final bool enableContextMenu;

  final Widget Function(Widget child) titleBuilder;

  final bool folded;
  final bool special;
  final bool paid;

  final bool dimmed;

  final bool highlight;

  final Widget? basement;
  final void Function()? onBasementPressed;

  @override
  State<ChatTile> createState() => _ChatTileState();

  /// Returns the [child].
  static Widget _defaultBuilder(Widget child) => child;
}

/// State of a [ChatTile] keeping the [_avatarKey] to prevent redraws.
class _ChatTileState extends State<ChatTile> {
  /// [GlobalKey] of an [AvatarWidget] preventing its redraws.
  final GlobalKey _avatarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final Color normal = style.colors.onPrimary;
    const Color paid = Color.fromRGBO(213, 232, 253, 1);
    final Color chosen =
        widget.active ? style.activeColor : style.selectedColor;

    final Border normalBorder =
        Border.all(color: style.colors.secondaryHighlight, width: 0.5);
    final Border hoverBorder =
        Border.all(color: style.colors.primaryHighlightShiniest, width: 0.5);
    final Border paidBorder =
        Border.all(color: style.colors.acceptPrimary, width: 0.5);
    final Border chosenBorder =
        Border.all(color: const Color(0xFF58A6EF), width: 0.5);

    final newGreenColor = Color.alphaBlend(
      style.colors.acceptPrimary.withOpacity(0.1),
      style.colors.onPrimary,
    );

    return ContextMenuRegion(
      key: Key('Chat_${widget.chat?.chat.value.id}'),
      preventContextMenu: false,
      actions: widget.actions,
      indicateOpenedMenu: true,
      enabled: widget.enableContextMenu,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 1.5, 0, 1.5),
        child: InkWellWithHover(
          selectedColor:
              widget.basement != null ? style.colors.acceptPrimary : chosen,
          unselectedColor: widget.dimmed
              ? style.colors.onPrimaryOpacity50
              : normal.darken(widget.darken),
          selectedHoverColor:
              widget.basement != null ? style.colors.acceptPrimary : chosen,
          unselectedHoverColor: widget.basement != null
              ? newGreenColor
              : widget.highlight
                  ? paid.darken(0.03)
                  : style.cardHoveredColor,
          // unselectedHoverColor:
          //     (widget.highlight ? paid : normal).darken(0.03),
          border: widget.basement != null
              ? paidBorder
              : widget.selected
                  ? chosenBorder
                  : normalBorder,
          hoveredBorder: widget.basement != null
              ? paidBorder
              : widget.selected
                  ? chosenBorder
                  : hoverBorder,
          selected: widget.selected || widget.active,
          borderRadius: style.cardRadius,
          onTap: widget.onTap,
          folded: widget.chat?.chat.value.favoritePosition != null,
          bookmarkColor:
              widget.basement != null ? style.colors.acceptPrimary : null,
          child: Column(
            children: [
              SizedBox(
                height: widget.basement == null
                    ? widget.height
                    : widget.height - 14,
                child: Padding(
                  key: widget.chat?.chat.value.favoritePosition != null
                      ? Key('FavoriteIndicator_${widget.chat?.chat.value.id}')
                      : null,
                  padding: EdgeInsets.fromLTRB(
                    12,
                    widget.basement == null ? 4 : 8,
                    12,
                    widget.basement == null ? 4 : 0,
                  ),
                  child: Row(
                    children: [
                      // AvatarWidget.fromRxChat(
                      //   widget.chat,
                      //   key: _avatarKey,
                      //   radius: 30,
                      // ),
                      widget.avatarBuilder(
                        AvatarWidget.fromRxChat(
                          widget.chat,
                          key: _avatarKey,
                          radius: AvatarRadius.large,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ...widget.leading,
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
                                        child: widget.titleBuilder(
                                          widget.chat == null
                                              ? Text(
                                                  ('dot'.l10n * 3),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: style.fonts.big.regular
                                                      .onBackground
                                                      .copyWith(
                                                    color: widget.selected ||
                                                            widget.active
                                                        ? style.colors.onPrimary
                                                        : style.colors
                                                            .onBackground,
                                                  ),
                                                )
                                              : Obx(() {
                                                  return Text(
                                                    widget.chat?.title.value ??
                                                        ('dot'.l10n * 3),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: style.fonts.big
                                                        .regular.onBackground
                                                        .copyWith(
                                                      color: widget.selected ||
                                                              widget.active
                                                          ? style
                                                              .colors.onPrimary
                                                          : style.colors
                                                              .onBackground,
                                                    ),
                                                  );
                                                }),
                                        ),
                                      ),
                                      ...widget.title,
                                    ],
                                  ),
                                ),
                                ...widget.status,
                              ],
                            ),
                            ...widget.subtitle,
                            // if (widget.basement != null)
                            //   Align(
                            //     alignment: Alignment.centerRight,
                            //     child: Padding(
                            //       padding: const EdgeInsets.only(top: 0),
                            //       child: DefaultTextStyle(
                            //         style: style.fonts.small.regular.onPrimary
                            //             .copyWith(
                            //           color: widget.selected
                            //               ? style.colors.onPrimary
                            //               : style.colors.primary,
                            //         ),
                            //         child: widget.basement!,
                            //       ),
                            //     ),
                            //   )
                          ],
                        ),
                      ),
                      ...widget.trailing,
                    ],
                  ),
                ),
              ),
              if (widget.basement != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: WidgetButton(
                    onPressed: widget.onBasementPressed,
                    child: Container(
                      decoration: BoxDecoration(
                        // color: style.colors.onBackgroundOpacity7,
                        color: widget.selected
                            ? style.colors.onBackgroundOpacity7
                            : style.colors.acceptPrimary.withOpacity(0.1),
                        // border: paidBorder,
                        border: Border(
                          top: BorderSide(
                            color: style.colors.acceptPrimary.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        borderRadius: style.cardRadius.copyWith(
                          topLeft: Radius.zero,
                          topRight: Radius.zero,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                      child: DefaultTextStyle(
                        style: style.fonts.small.regular.onPrimary.copyWith(
                          color: widget.selected
                              ? style.colors.onPrimary
                              : style.colors.primary,
                        ),
                        child: widget.basement!,
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

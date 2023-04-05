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
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';

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
    this.title = const [],
    this.status = const [],
    this.subtitle = const [],
    this.leading = const [],
    this.trailing = const [],
    this.actions = const [],
    this.selected = false,
    this.outlined = false,
    this.onTap,
    this.height = 94,
    this.darken = 0,
    Widget Function(Color, Widget)? avatarBuilder,
    this.enableContextMenu = true,
    this.folded = false,
    this.special = false,
    this.highlight = false,
    this.invert = false,
  }) : avatarBuilder = avatarBuilder ?? _defaultAvatarBuilder;

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
  final Widget Function(Color badgeColor, Widget child) avatarBuilder;

  /// Indicator whether context menu should be enabled over this [ChatTile].
  final bool enableContextMenu;

  final bool folded;
  final bool special;
  final bool highlight;
  final bool invert;

  @override
  State<ChatTile> createState() => _ChatTileState();

  /// Returns the [child].
  static Widget _defaultAvatarBuilder(Color badgeColor, Widget child) => child;
}

class _ChatTileState extends State<ChatTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    // const Color unselected = Color.fromARGB(255, 248, 255, 250);
    const Color unselected = Color.fromARGB(255, 241, 250, 244);
    const Color hovered = Color.fromARGB(255, 222, 245, 228);
    const Color tapped = Color.fromRGBO(189, 224, 198, 1);

    final Border specialBorder = Border.all(
      // color: Color(0xFFbde0c6),
      // color: Colors.orange,
      // color: Colors.amber,
      // color: Color(0xFFD0D0D0),
      // color: Theme.of(context).colorScheme.secondary,
      color: style.cardHoveredBorder.top.color.darken(0.1),
      width: 1,
    );

    // final Border specialBorderGrey =
    //     Border.all(color: Color(0xFF8383ff), width: 1);
    final Border specialBorderGrey = Border.all(
      // color: Color(0xFFbde0c6),
      // color: Colors.orange,
      // color: Colors.amber,
      color: Color(0xFFD0D0D0),
      // color: Color(0xFFDEDEDE),
      // color: const Color(0xFFEBEBEB),
      width: 1,
    );
    // final Border specialBorderGrey =
    //     Border.all(color: Color(0xFFD0D0D0), width: 1);

    final Color secondary = Theme.of(context).colorScheme.secondary;

    // const Color normal = Colors.white;
    // const Color hover = Color.fromARGB(255, 181, 225, 255);
    // const Color paid = Color.fromRGBO(211, 237, 255, 1);
    // const Color chosen = Color(0xFF63B4FF);

    // const Color normal = Colors.white;
    // const Color hover = Color(0xFF96cdff);
    // const Color paid = Color(0xFFc9e5ff);
    // const Color chosen = Color.fromARGB(255, 63, 182, 255);

    const Color normal = Colors.white;
    const Color hover = Color(0xFFd0e9ff);
    const Color paid = Color(0xFFe0f0ff);
    const Color chosen = Color(0xFF63B4FF);

    final Border normalBorder = Border.all(
      color: const Color(0xFFEBEBEB),
      width: 0.5,
    );
    final Border hoverBorder = Border.all(
      color: const Color(0xFFCAE6FE),
      width: 0.5,
    );
    final Border paidBorder = Border.all(
      color: const Color(0xFFDCEBFA),
      width: 0.5,
    );
    final Border chosenBorder = Border.all(
      color: const Color(0xFF58A6EF),
      width: 0.5,
    );

    return ContextMenuRegion(
      key: Key('Chat_${widget.chat?.chat.value.id}'),
      preventContextMenu: false,
      actions: widget.actions,
      indicateOpenedMenu: true,
      enabled: widget.enableContextMenu,
      child: SizedBox(
        height: widget.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: FoldedWidget(
            radius: 15,
            folded: widget.folded,
            child: InkWellWithHover(
              onHover: (b) => setState(() => _hovered = b),
              selectedColor: chosen,
              unselectedColor: widget.highlight ? paid : normal,
              selectedHoverColor: chosen,
              unselectedHoverColor:
                  (widget.highlight ? paid : normal).darken(0.03),

              border: widget.selected
                  ? chosenBorder
                  : widget.highlight
                      ? paidBorder
                      : normalBorder,
              hoveredBorder: widget.selected ? chosenBorder : hoverBorder,

              // selectedColor: invert
              //     ? secondary
              //     : special
              //         ? tapped
              //         : style.cardSelectedColor,
              // unselectedColor: special
              //     ? unselected
              //     : highlight
              //         ? style.cardHoveredColor.darken(darken)
              //         : style.cardColor.darken(darken),
              selected: widget.selected,
              // outlined: outlined,
              // // hoveredBorder:
              // //     selected ? style.primaryBorder : style.cardHoveredBorder,
              // // border: selected ? style.primaryBorder : style.cardBorder,
              // hoveredBorder: outlined
              //     ? selected
              //         ? specialBorder
              //         : specialBorderGrey
              //     : selected
              //         ? style.primaryBorder
              //         : style.cardHoveredBorder,
              // border: outlined
              //     ? selected
              //         ? specialBorder
              //         : specialBorderGrey
              //     : selected
              //         ? style.primaryBorder
              //         : style.cardBorder,
              borderRadius: style.cardRadius,
              onTap: widget.onTap,
              // unselectedHoverColor: style.cardSelectedColor,
              // // special ? hovered : style.cardHoveredColor.darken(darken),
              // selectedHoverColor: invert
              //     ? secondary
              //     : special
              //         ? tapped
              //         : style.cardSelectedColor,
              // selectedHoverColor: style.cardHoveredColor.darken(darken),
              // selectedHoverColor: style.cardSelectedColor.darken(0.03),
              folded: widget.chat?.chat.value.favoritePosition != null,
              child: Padding(
                key: widget.chat?.chat.value.favoritePosition != null
                    ? Key('FavoriteIndicator_${widget.chat?.chat.value.id}')
                    : null,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Row(
                  children: [
                    widget.avatarBuilder(
                      // widget.selected
                      //     ? chosen
                      //     : _hovered
                      //         ? hover
                      //         : normal,
                      Colors.white,
                      AvatarWidget.fromRxChat(
                        widget.chat,
                        radius: 30,
                        // badgeColor: widget.selected
                        //     ? chosen
                        //     : _hovered
                        //         ? hover
                        //         : normal,
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
                                      child: Obx(() {
                                        return Text(
                                          widget.chat?.title.value ??
                                              ('dot'.l10n * 3),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: widget.invert
                                                    ? Colors.white
                                                    : null,
                                              ),
                                        );
                                      }),
                                    ),
                                    ...widget.title,
                                  ],
                                ),
                              ),
                              ...widget.status,
                            ],
                          ),
                          ...widget.subtitle,
                        ],
                      ),
                    ),
                    ...widget.trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

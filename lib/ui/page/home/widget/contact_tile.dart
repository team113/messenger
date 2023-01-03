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

import '/domain/model/contact.dart';
import '/domain/model/my_user.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/tab/chats/widget/hovered_ink.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/util/platform_utils.dart';

/// Person ([ChatContact] or [User]) visual representation.
///
/// If both specified, the [contact] will be used.
class ContactTile extends StatefulWidget {
  const ContactTile({
    Key? key,
    this.contact,
    this.user,
    this.myUser,
    this.leading = const [],
    this.trailing = const [],
    this.onTap,
    this.selected = false,
    this.subtitle = const [],
    this.darken = 0,
    this.height = 86,
    this.radius = 30,
    this.actions,
    this.folded = false,
    this.preventContextMenu = false,
    this.margin = const EdgeInsets.symmetric(vertical: 3),
    this.reorderIndex,
    this.showShadow = false,
    this.animateAvatarBadge = true,
  }) : super(key: key);

  /// [MyUser] to display.
  final MyUser? myUser;

  /// [RxChatContact] to display.
  final RxChatContact? contact;

  /// [RxUser] to display.
  final RxUser? user;

  /// Optional leading [Widget]s.
  final List<Widget> leading;

  /// Optional trailing [Widget]s.
  final List<Widget> trailing;

  /// Callback, called when this [Widget] is tapped.
  final void Function()? onTap;

  /// Indicator whether this [ContactTile] is selected.
  final bool selected;

  /// Amount of darkening to apply to the background of this [ContactTile].
  final double darken;

  /// Indicator whether this [ContactTile] should have its corner folded.
  final bool folded;

  /// Indicator whether a default context menu should be prevented or not.
  ///
  /// Only effective under the web, since only web has a default context menu.
  final bool preventContextMenu;

  /// [ContextMenuRegion.actions] of this [ContactTile].
  final List<ContextMenuButton>? actions;

  /// Margin to apply to this [ContactTile].
  final EdgeInsets margin;

  /// Optional subtitle [Widget]s.
  final List<Widget> subtitle;

  /// Height of this [ContactTile].
  final double height;

  /// Radius of an [AvatarWidget] this [ContactTile] displays.
  final double radius;

  /// Reorderable index.
  final int? reorderIndex;

  /// Indicator whether this [ContactTile] should be with shadow or not.
  final bool showShadow;

  /// Indicator whether avatar [Badge] should be animated or not.
  final bool animateAvatarBadge;

  @override
  State<ContactTile> createState() => _ContactTileState();
}

/// [State] of [ContactTile].
class _ContactTileState extends State<ContactTile> {
  /// Indicator whether this [ContactTile] should be with shadow or not.
  bool showShadow = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        showShadow = widget.showShadow;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    Widget child = InkWellWithHover(
      selectedColor: style.cardSelectedColor,
      unselectedColor: style.cardColor.darken(widget.darken),
      selected: widget.selected,
      hoveredBorder:
          widget.selected ? style.primaryBorder : style.cardHoveredBorder,
      border: widget.selected ? style.primaryBorder : style.cardBorder,
      borderRadius: style.cardRadius,
      onTap: widget.onTap,
      unselectedHoverColor: style.cardHoveredColor.darken(widget.darken),
      selectedHoverColor: style.cardSelectedColor,
      folded: widget.contact?.contact.value.favoritePosition != null,
      child: Padding(
        key: widget.contact?.contact.value.favoritePosition != null
            ? Key('FavoriteIndicator_${widget.contact?.contact.value.id}')
            : null,
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Row(
          children: [
            ...widget.leading,
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.contact?.contact.value.name.val ??
                              widget
                                  .contact?.user.value?.user.value.name?.val ??
                              widget.contact?.user.value?.user.value.num.val ??
                              widget.user?.user.value.name?.val ??
                              widget.user?.user.value.num.val ??
                              widget.myUser?.name?.val ??
                              widget.myUser?.num.val ??
                              (widget.myUser == null
                                  ? '...'
                                  : 'btn_your_profile'.l10n),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
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
    );

    return ContextMenuRegion(
      key: widget.contact != null || widget.user != null
          ? Key(
              'ContextMenuRegion_${widget.contact?.id ?? widget.user?.id ?? widget.myUser?.id}')
          : null,
      preventContextMenu: widget.preventContextMenu,
      actions: widget.actions ?? [],
      child: widget.showShadow == true
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                boxShadow: [
                  if (showShadow)
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 5,
                      offset: const Offset(0, 0),
                    ),
                ],
                borderRadius: style.cardRadius.copyWith(
                    topLeft:
                        Radius.circular(style.cardRadius.topLeft.x * 1.75)),
              ),
              padding: widget.margin,
              child: child,
            )
          : Padding(
              padding: widget.margin,
              child: child,
            ),
    );
  }

  /// Returns [AvatarWidget] wrapped with reorderable listener if [reorderIndex]
  /// is not `null`.
  Widget _buildAvatar() {
    Widget child;

    if (widget.contact != null) {
      child = AvatarWidget.fromRxContact(
        widget.contact,
        radius: widget.radius,
        animateAvatarBadge: widget.animateAvatarBadge,
      );
    } else if (widget.user != null) {
      child = AvatarWidget.fromRxUser(
        widget.user,
        radius: widget.radius,
        animateAvatarBadge: widget.animateAvatarBadge,
      );
    } else {
      child = AvatarWidget.fromMyUser(
        widget.myUser,
        radius: widget.radius,
        animateAvatarBadge: widget.animateAvatarBadge,
      );
    }

    if (widget.reorderIndex != null) {
      if (PlatformUtils.isMobile) {
        child = ReorderableDelayedDragStartListener(
          key: Key('ContactReorder_${widget.contact?.id.val}'),
          index: widget.reorderIndex!,
          child: child,
        );
      } else {
        child = ReorderableDragStartListener(
          key: Key('ContactReorder_${widget.contact?.id.val}'),
          index: widget.reorderIndex!,
          child: child,
        );
      }
    }

    return child;
  }
}

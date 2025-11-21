// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/contact.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/tab/chats/widget/hovered_ink.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';

/// Person ([ChatContact] or [User]) visual representation.
///
/// If both specified, the [contact] will be used.
class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    this.contact,
    this.user,
    this.myUser,
    this.leading = const [],
    this.trailing = const [],
    this.onTap,
    this.selected = false,
    this.subtitle = const [],
    this.darken = 0,
    this.height = 80,
    this.radius = AvatarRadius.large,
    this.actions,
    this.folded = false,
    this.dense = false,
    this.preventContextMenu = false,
    this.padding,
    this.margin = const EdgeInsets.fromLTRB(0, 1.5, 0, 1.5),
    Widget Function(Widget)? avatarBuilder,
    this.enableContextMenu = true,
  }) : avatarBuilder = avatarBuilder ?? _defaultAvatarBuilder;

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

  /// Indicator whether this [ContactTile] should be dense.
  final bool dense;

  /// Indicator whether a default context menu should be prevented or not.
  ///
  /// Only effective under the web, since only web has a default context menu.
  final bool preventContextMenu;

  /// [ContextMenuRegion.actions] of this [ContactTile].
  final List<ContextMenuItem>? actions;

  /// Margin to apply to this [ContactTile].
  final EdgeInsets margin;

  /// Padding to apply to this [ContactTile].
  final EdgeInsets? padding;

  /// Optional subtitle [Widget]s.
  final List<Widget> subtitle;

  /// Height of this [ContactTile].
  final double height;

  /// Radius of an [AvatarWidget] this [ContactTile] displays.
  final AvatarRadius radius;

  /// Builder for building an [AvatarWidget] this [ContactTile] displays.
  ///
  /// Intended to be used to allow custom [Badge]s, [InkWell]s, etc over the
  /// [AvatarWidget].
  final Widget Function(Widget child) avatarBuilder;

  /// Indicator whether context menu should be enabled over this [ContactTile].
  final bool enableContextMenu;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ContextMenuRegion(
      key: contact != null || user != null
          ? Key('ContextMenuRegion_${contact?.id ?? user?.id ?? myUser?.id}')
          : null,
      preventContextMenu: preventContextMenu,
      actions: actions ?? [],
      indicateOpenedMenu: true,
      enabled: enableContextMenu,
      child: Padding(
        padding: margin,
        child: InkWellWithHover(
          selectedColor: style.colors.primary,
          unselectedColor: style.cardColor.darken(darken),
          selected: selected,
          hoveredBorder: selected
              ? style.cardSelectedBorder
              : style.cardHoveredBorder,
          border: selected
              ? style.cardSelectedBorder
              : Border.all(
                  color: style.colors.secondaryHighlightDarkest,
                  width: 0.5,
                ),
          borderRadius: style.cardRadius,
          onTap: onTap,
          unselectedHoverColor: style.cardHoveredColor,
          selectedHoverColor: style.colors.primary,
          folded: contact?.contact.value.favoritePosition != null,
          child: SizedBox(
            height: dense ? 62 : height,
            child: Padding(
              key: contact?.contact.value.favoritePosition != null
                  ? Key('FavoriteIndicator_${contact?.contact.value.id}')
                  : null,
              padding:
                  padding ??
                  EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 4 : 6),
              child: Row(
                children: [
                  ...leading,
                  avatarBuilder(
                    contact != null
                        ? AvatarWidget.fromRxContact(
                            contact,
                            radius: dense ? AvatarRadius.medium : radius,
                          )
                        : user != null
                        ? AvatarWidget.fromRxUser(
                            user,
                            radius: dense ? AvatarRadius.medium : radius,
                          )
                        : AvatarWidget.fromMyUser(
                            myUser,
                            radius: dense ? AvatarRadius.medium : radius,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (contact != null || user != null)
                          Obx(() {
                            return _name(
                              context,
                              contact: contact?.contact.value,
                              user: user,
                            );
                          })
                        else
                          _name(context),
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

  /// Returns [Text] representing the [contact], [user] or [myUser] name.
  Widget _name(BuildContext context, {ChatContact? contact, RxUser? user}) {
    final style = Theme.of(context).style;

    return Text(
      contact?.name.val ??
          user?.title() ??
          myUser?.name?.val ??
          myUser?.num.toString() ??
          'dot'.l10n,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: selected
          ? style.fonts.medium.regular.onPrimary
          : style.fonts.medium.regular.onBackground,
    );
  }

  /// Returns the [child].
  ///
  /// Uses [GestureDetector] with a dummy [GestureDetector.onLongPress] callback
  /// for discarding long presses on its [child].
  static Widget _defaultAvatarBuilder(Widget child) =>
      GestureDetector(onLongPress: () {}, child: child);
}

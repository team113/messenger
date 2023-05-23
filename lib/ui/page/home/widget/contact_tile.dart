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
    this.height = 86,
    this.radius = 30,
    this.actions,
    this.folded = false,
    this.dense = false,
    this.preventContextMenu = false,
    this.margin = const EdgeInsets.symmetric(vertical: 3),
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

  /// Optional subtitle [Widget]s.
  final List<Widget> subtitle;

  /// Height of this [ContactTile].
  final double height;

  /// Radius of an [AvatarWidget] this [ContactTile] displays.
  final double radius;

  /// Builder for building an [AvatarWidget] this [ContactTile] displays.
  ///
  /// Intended to be used to allow custom [Badge]s, [InkWell]s, etc over the
  /// [AvatarWidget].
  final Widget Function(Widget child) avatarBuilder;

  /// Indicator whether context menu should be enabled over this [ContactTile].
  final bool enableContextMenu;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    final TextStyle headlineSmall = Theme.of(context).textTheme.headlineSmall!;

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
          hoveredBorder:
              selected ? style.cardSelectedBorder : style.cardHoveredBorder,
          border: selected ? style.cardSelectedBorder : style.cardBorder,
          borderRadius: style.cardRadius,
          onTap: onTap,
          unselectedHoverColor: style.cardColor.darken(darken + 0.03),
          selectedHoverColor: style.colors.primary,
          folded: contact?.contact.value.favoritePosition != null,
          child: Padding(
            key: contact?.contact.value.favoritePosition != null
                ? Key('FavoriteIndicator_${contact?.contact.value.id}')
                : null,
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: dense ? 11 : 14,
            ),
            child: Row(
              children: [
                ...leading,
                avatarBuilder(
                  contact != null
                      ? AvatarWidget.fromRxContact(
                          contact,
                          radius: dense ? 17 : radius,
                        )
                      : user != null
                          ? AvatarWidget.fromRxUser(
                              user,
                              radius: dense ? 17 : radius,
                            )
                          : AvatarWidget.fromMyUser(
                              myUser,
                              radius: dense ? 17 : radius,
                            ),
                ),
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
                              contact?.contact.value.name.val ??
                                  user?.user.value.name?.val ??
                                  user?.user.value.num.val ??
                                  myUser?.name?.val ??
                                  myUser?.num.val ??
                                  (myUser == null
                                      ? '...'
                                      : 'btn_your_profile'.l10n),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: headlineSmall.copyWith(
                                color: selected ? style.colors.onPrimary : null,
                              ),
                            ),
                          ),
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
    );
  }

  /// Returns the [child].
  ///
  /// Uses [GestureDetector] with a dummy [GestureDetector.onLongPress] callback
  /// for discarding long presses on its [child].
  static Widget _defaultAvatarBuilder(Widget child) => GestureDetector(
        onLongPress: () {},
        child: child,
      );
}

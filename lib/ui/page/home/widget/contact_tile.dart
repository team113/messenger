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
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/hovered_ink.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';

import '/domain/model/contact.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/ui/page/home/widget/avatar.dart';

/// Person ([ChatContact] or [User]) visual representation.
///
/// If both specified, the [contact] will be used.
class ContactTile extends StatelessWidget {
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
    this.canDelete = false,
    this.onDelete,
    this.folded = false,
    this.preventContextMenu = false,
    this.margin = const EdgeInsets.symmetric(vertical: 3),
    this.onBadgeTap,
    this.onAvatarTap,
    this.showBadge = true,
    this.border,
  }) : super(key: key);

  final MyUser? myUser;

  /// [RxChatContact] to display.
  final RxChatContact? contact;

  /// [RxUser] to display.
  final RxUser? user;

  /// Optional leading [Widget]s.
  final List<Widget> leading;

  /// Optional trailing [Widget]s.
  final List<Widget> trailing;

  final bool canDelete;
  final void Function()? onDelete;

  /// Callback, called when this [Widget] is tapped.
  final void Function()? onTap;

  /// Indicator whether this [ContactTile] is selected.
  final bool selected;

  /// Amount of darkening to apply to the background of this [ContactTile].
  final double darken;

  final bool folded;

  final bool preventContextMenu;
  final List<ContextMenuButton>? actions;
  final EdgeInsets margin;

  /// Optional subtitle [Widget]s.
  final List<Widget> subtitle;

  /// Height of this [ContactTile].
  final double height;

  /// Radius of an [AvatarWidget] this [ContactTile] displays.
  final double radius;

  final void Function()? onBadgeTap;
  final void Function()? onAvatarTap;
  final bool showBadge;

  final Border? border;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return ContextMenuRegion(
      key: contact != null || user != null
          ? Key('ContextMenuRegion_${contact?.id ?? user?.id ?? myUser?.id}')
          : null,
      preventContextMenu: preventContextMenu,
      actions: actions ?? [],
      child: Container(
        margin: margin,
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
          folded: contact?.contact.value.favoritePosition != null,
          child: Padding(
            key: contact?.contact.value.favoritePosition != null
                ? Key('FavoriteIndicator_${contact?.contact.value.id}')
                : null,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Row(
              children: [
                ...leading,
                if (contact != null)
                  AvatarWidget.fromRxContact(
                    contact,
                    radius: radius,
                    showBadge: showBadge,
                  )
                else if (user != null)
                  AvatarWidget.fromRxUser(
                    user,
                    radius: radius,
                    showBadge: showBadge,
                  )
                else
                  AvatarWidget.fromMyUser(
                    myUser,
                    radius: radius,
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
                                  contact?.user.value?.user.value.name?.val ??
                                  contact?.user.value?.user.value.num.val ??
                                  user?.user.value.name?.val ??
                                  user?.user.value.num.val ??
                                  myUser?.name?.val ??
                                  myUser?.num.val ??
                                  (myUser == null
                                      ? '...'
                                      : 'btn_your_profile'.l10n),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.headline5,
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
}

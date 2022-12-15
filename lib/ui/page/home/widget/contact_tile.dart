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
    this.unselectedColor,
    this.selectedColor,
    this.selectedHoverColor,
    this.unselectedHoverColor,
    this.border,
    this.hoveredBorder,
    this.padding = const EdgeInsets.fromLTRB(12, 14, 12, 14),
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

  /// Optional subtitle [Widget]s.
  final List<Widget> subtitle;

  /// Height of this [ContactTile].
  final double height;

  /// Radius of an [AvatarWidget] this [ContactTile] displays.
  final double radius;

  /// Background color of unselected this [ContactTile].
  final Color? unselectedColor;

  /// Background color of selected this [ContactTile].
  final Color? selectedColor;

  /// Background hover color of selected this [ContactTile].
  final Color? selectedHoverColor;

  /// Background hover color of unselected this [ContactTile].
  final Color? unselectedHoverColor;

  /// [Border] of this [ContactTile].
  final Border? border;

  /// Hovered [Border] of this [ContactTile].
  final Border? hoveredBorder;

  /// Padding of this [ChatTile].
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return ContextMenuRegion(
      key: contact != null || user != null
          ? Key('ContextMenuRegion_${contact?.id ?? user?.id ?? myUser?.id}')
          : null,
      preventContextMenu: preventContextMenu,
      actions: actions ?? [],
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: InkWellWithHover(
            selectedColor: selectedColor ?? style.cardSelectedColor,
            unselectedColor: unselectedColor ?? style.cardColor.darken(darken),
            selected: selected,
            hoveredBorder: hoveredBorder ??
                (selected ? style.primaryBorder : style.cardHoveredBorder),
            border:
                border ?? (selected ? style.primaryBorder : style.cardBorder),
            borderRadius: style.cardRadius,
            onTap: onTap,
            unselectedHoverColor:
                unselectedHoverColor ?? style.cardHoveredColor.darken(darken),
            selectedHoverColor: selectedHoverColor ?? style.cardSelectedColor,
            folded: contact?.contact.value.favoritePosition != null,
            child: Container(
              key: contact?.contact.value.favoritePosition != null
                  ? Key('FavoriteIndicator_${contact?.contact.value.id}')
                  : null,
              height: height,
              padding: padding,
              child: Row(
                children: [
                  ...leading,
                  if (contact != null)
                    AvatarWidget.fromRxContact(contact, radius: radius)
                  else if (user != null)
                    AvatarWidget.fromRxUser(user, radius: radius)
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
      ),
    );
  }
}

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
import 'package:get/get.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/user/controller.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';

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
    this.darken = 0.05,
    this.actions,
    this.canDelete = false,
    this.onDelete,
    this.subtitle = const [],
    this.preventContextMenu = false,
  }) : super(key: key);

  final RxChatContact? contact;
  final RxUser? user;
  final MyUser? myUser;

  final List<Widget> leading;
  final List<Widget> trailing;

  final bool canDelete;
  final void Function()? onDelete;

  final void Function()? onTap;
  final bool selected;
  final double darken;

  final bool preventContextMenu;
  final List<ContextMenuButton>? actions;

  final List<Widget> subtitle;

  @override
  Widget build(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;

    return SizedBox(
      height: 84,
      child: ContextMenuRegion(
        key: contact != null || user != null
            ? Key('ContextMenuRegion_${contact?.id ?? user?.id ?? myUser?.id}')
            : null,
        preventContextMenu: preventContextMenu,
        actions: actions,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            border: style.cardBorder,
            color: Colors.transparent,
          ),
          child: Material(
            type: MaterialType.card,
            borderRadius: style.cardRadius,
            color: selected
                ? const Color(0xFFD7ECFF).withOpacity(0.8)
                : style.cardColor.darken(darken),
            child: InkWell(
              borderRadius: style.cardRadius,
              onTap: onTap,
              hoverColor: selected
                  ? const Color(0x00D7ECFF)
                  : const Color.fromARGB(255, 244, 249, 255),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
                child: Row(
                  children: [
                    ...leading,
                    if (contact != null)
                      AvatarWidget.fromRxContact(contact, radius: 26)
                    else if (user != null)
                      AvatarWidget.fromRxUser(user, radius: 26)
                    else
                      AvatarWidget.fromMyUser(myUser, radius: 26),
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
                                      contact
                                          ?.user.value?.user.value.name?.val ??
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
      ),
    );
  }
}

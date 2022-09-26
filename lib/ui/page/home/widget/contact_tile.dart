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
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';

/// Person ([ChatContact] or [User]) visual representation.
///
/// If both specified, the [contact] will be used.
class ContactTile extends StatelessWidget {
  const ContactTile({
    Key? key,
    this.contact,
    this.user,
    this.leading = const [],
    this.trailing = const [],
    this.onTap,
    this.selected = false,
    this.darken = 0.05,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;

    return Container(
      constraints: const BoxConstraints(minHeight: 76),
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
              : const Color(0xFFD7ECFF).withOpacity(0.8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ...leading,
                if (contact != null)
                  AvatarWidget.fromRxContact(contact, radius: 26)
                else
                  AvatarWidget.fromRxUser(user, radius: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    contact?.contact.value.name.val ??
                        contact?.user.value?.user.value.name?.val ??
                        contact?.user.value?.user.value.num.val ??
                        user?.user.value.name?.val ??
                        user?.user.value.num.val ??
                        '...',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headline5,
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

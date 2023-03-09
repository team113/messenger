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

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/routes.dart';
import '/ui/page/home/widget/chat_tile.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/selected_dot.dart';
import '/ui/widget/widget_button.dart';

/// Selectable tile representing the provided [Chat], [User], [ChatContact] or
/// [MyUser].
class SelectedTile extends StatelessWidget {
  const SelectedTile({
    super.key,
    this.user,
    this.myUser,
    this.contact,
    this.chat,
    this.selected = false,
    this.subtitle = const [],
    this.onTap,
    this.darken = 0,
    this.onAvatarTap = _defaultAvatarTap,
  });

  /// [RxUser] this [SelectedTile] is about.
  final RxUser? user;

  /// [RxChat] this [SelectedTile] is about.
  final RxChat? chat;

  /// [MyUser] this [SelectedTile] is about.
  final MyUser? myUser;

  /// [RxChatContact] this [SelectedTile] is about.
  final RxChatContact? contact;

  /// Indicator whether this [SelectedTile] is selected.
  final bool selected;

  /// Optional subtitle [Widget]s to put into [ContactTile.subtitle] or
  /// [ChatTile.subtitle].
  final List<Widget> subtitle;

  /// Callback, called when this [SelectedTile] is pressed.
  final void Function()? onTap;

  /// Amount of darkening to apply to the background of [ContactTile] or
  /// [ChatTile].
  final double darken;

  /// Callback, called when an [AvatarWidget] of this [SelectedTile] is pressed.
  final void Function(UserId id)? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: chat == null
          ? ContactTile(
              contact: contact,
              user: user,
              myUser: myUser,
              selected: selected,
              subtitle: subtitle,
              darken: darken,
              onTap: onTap,
              avatarBuilder: (c) => WidgetButton(
                onPressed: onAvatarTap == null
                    ? onTap
                    : () => onAvatarTap!(
                          user?.id ?? contact?.user.value?.id ?? myUser!.id,
                        ),
                child: c,
              ),
              trailing: [
                if (myUser == null)
                  SelectedDot(selected: selected, darken: darken)
              ],
            )
          : ChatTile(
              key: Key('Chat_${chat!.id}'),
              chat: chat,
              selected: selected,
              subtitle: subtitle,
              onTap: onTap,
              darken: darken,
              trailing: [
                if (myUser == null)
                  SelectedDot(selected: selected, darken: darken)
              ],
            ),
    );
  }

  /// Opens the [Router.user] page with the provided [id].
  static void _defaultAvatarTap(UserId id) => router.user(id);
}

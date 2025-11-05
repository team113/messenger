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

import '../widget/headlines.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/tab/chats/widget/recent_chat.dart';
import '/ui/page/home/widget/chat_tile.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/style/page/widgets/common/dummy_chat.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/selected_dot.dart';

/// [Routes.style] tiles section.
class TilesSection {
  /// Returns the [Widget]s of this [TilesSection].
  static List<Widget> build(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      const Headlines(
        children: [
          (
            headline: 'ContextMenu(desktop)',
            widget: ContextMenu(
              actions: [
                ContextMenuButton(label: 'Action 1'),
                ContextMenuButton(label: 'Action 2'),
                ContextMenuButton(label: 'Action 3'),
                ContextMenuDivider(),
                ContextMenuButton(label: 'Action 4'),
              ],
            ),
          ),
          (
            headline: 'ContextMenu(mobile)',
            widget: ContextMenu(
              enlarged: true,
              actions: [
                ContextMenuButton(label: 'Action 1', enlarged: true),
                ContextMenuButton(label: 'Action 2', enlarged: true),
                ContextMenuButton(label: 'Action 3', enlarged: true),
                ContextMenuButton(label: 'Action 4', enlarged: true),
              ],
            ),
          ),
        ],
      ),
      Headlines(
        color: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        children: [
          (
            headline: 'RecentChatTile',
            widget: RecentChatTile(DummyRxChat(), onTap: () {}),
          ),
          (
            headline: 'RecentChatTile(selected)',
            widget: RecentChatTile(DummyRxChat(), onTap: () {}, selected: true),
          ),
          (
            headline: 'RecentChatTile(trailing)',
            widget: RecentChatTile(
              DummyRxChat(),
              onTap: () {},
              selected: false,
              trailing: const [SelectedDot(selected: false)],
            ),
          ),
        ],
      ),
      Headlines(
        color: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        children: [
          (
            headline: 'ChatTile',
            widget: ChatTile(chat: DummyRxChat(), onTap: () {}),
          ),
          (
            headline: 'ChatTile(selected)',
            widget: ChatTile(chat: DummyRxChat(), onTap: () {}, selected: true),
          ),
        ],
      ),
      Builder(
        builder: (context) {
          final MyUser myUser = MyUser(
            id: const UserId('123'),
            num: UserNum('1234123412341234'),
            emails: MyUserEmails(confirmed: []),
            phones: MyUserPhones(confirmed: []),
            presenceIndex: 0,
            online: true,
          );

          return Headlines(
            color: Color.alphaBlend(
              style.sidebarColor,
              style.colors.onBackgroundOpacity7,
            ),
            children: [
              (
                headline: 'ContactTile',
                widget: ContactTile(myUser: myUser, onTap: () {}),
              ),
              (
                headline: 'ContactTile(selected)',
                widget: ContactTile(
                  myUser: myUser,
                  onTap: () {},
                  selected: true,
                ),
              ),
              (
                headline: 'ContactTile(trailing)',
                widget: ContactTile(
                  myUser: myUser,
                  onTap: () {},
                  selected: false,
                  trailing: const [SelectedDot(selected: false)],
                ),
              ),
            ],
          );
        },
      ),
    ];
  }
}

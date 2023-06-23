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

import '/domain/model/chat.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';

/// [Widget] which returns a visual representation of the [Chat.unreadCount]
/// counter.
class UnreadCounter extends StatelessWidget {
  const UnreadCounter(this.rxChat, this.inverted, {super.key});

  /// [RxChat] this [RecentChatTile] is about.
  final RxChat rxChat;

  /// Indicator of whether this [RecentChatTile] is selected and should be
  /// inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final Chat chat = rxChat.chat.value;
    final bool muted = chat.muted != null;

    if (rxChat.unreadCount.value > 0) {
      return Container(
        key: const Key('UnreadMessages'),
        margin: const EdgeInsets.only(left: 4),
        width: 23,
        height: 23,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: muted
              ? inverted
                  ? style.colors.onPrimary
                  : const Color(0xFFC0C0C0)
              : style.colors.dangerColor,
        ),
        alignment: Alignment.center,
        child: Text(
          // TODO: Implement and test notations like `4k`, `54m`, etc.
          rxChat.unreadCount.value > 99
              ? '99${'plus'.l10n}'
              : '${rxChat.unreadCount.value}',
          style: TextStyle(
            color: muted
                ? inverted
                    ? style.colors.secondary
                    : style.colors.onPrimary
                : style.colors.onPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
        ),
      );
    }

    return const SizedBox(key: Key('NoUnreadMessages'));
  }
}

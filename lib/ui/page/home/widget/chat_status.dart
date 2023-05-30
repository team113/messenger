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
import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/themes.dart';

/// [Widget] which builds a [ChatItem.status] visual representation.
class ChatStatus extends StatelessWidget {
  const ChatStatus(this.rxChat, this.me, this.inverted, {super.key});

  /// [RxChat] this [RecentChatTile] is about.
  final RxChat rxChat;

  /// [UserId] of the authenticated [MyUser].
  final UserId? me;

  /// Indicator of whether this [RecentChatTile] is selected and should be
  /// inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final Chat chat = rxChat.chat.value;

    final ChatItem? item;
    if (rxChat.messages.isNotEmpty) {
      item = rxChat.messages.last.value;
    } else {
      item = chat.lastItem;
    }

    if (item != null && item.authorId == me && !chat.isMonolog) {
      final bool isSent = item.status.value == SendingStatus.sent;
      final bool isRead =
          chat.members.length <= 1 ? isSent : chat.isRead(item, me) && isSent;
      final bool isDelivered = isSent && !chat.lastDelivery.isBefore(item.at);
      final bool isError = item.status.value == SendingStatus.error;
      final bool isSending = item.status.value == SendingStatus.sending;

      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Icon(
          isRead || isDelivered
              ? Icons.done_all
              : isSending
                  ? Icons.access_alarm
                  : isError
                      ? Icons.error_outline
                      : Icons.done,
          color: isRead
              ? inverted
                  ? style.colors.onPrimary
                  : style.colors.primary
              : isError
                  ? style.colors.dangerColor
                  : inverted
                      ? style.colors.onPrimary
                      : style.colors.secondary,
          size: 16,
        ),
      );
    }

    return const SizedBox();
  }
}

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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';

import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/avatar.dart';

/// [Widget] which builds a tile representation of the [CallController.chat].
class ChatCardPreview extends StatelessWidget {
  const ChatCardPreview({
    super.key,
    required this.actualMembers,
    required this.openAddMember,
    required this.duration,
    required this.me,
    this.chat,
  });

  /// [Set] of user IDs who are currently active in the chat.
  final Set<UserId> actualMembers;

  /// [RxChat] object representing the chat, or null if there is no chat.
  final RxChat? chat;

  /// Callback [Function] that opens a screen to add members to the chat.
  final Future<void> Function() openAddMember;

  /// [Rx] object representing the current duration of the call.
  final Rx<Duration> duration;

  /// [CallMember] object representing the current user.
  final CallMember me;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Style style = Theme.of(context).extension<Style>()!;

      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            color: Colors.transparent,
          ),
          child: Material(
            type: MaterialType.card,
            borderRadius: style.cardRadius,
            color: const Color(0x794E5A78),
            child: InkWell(
              borderRadius: style.cardRadius,
              onTap: openAddMember,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
                child: Row(
                  children: [
                    AvatarWidget.fromRxChat(chat, radius: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat?.title.value ?? 'dot'.l10n * 3,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                              Text(
                                duration.value.hhMmSs(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Row(
                              children: [
                                Text(
                                  chat?.members.values
                                          .firstWhereOrNull(
                                            (e) => e.id != me.id.userId,
                                          )
                                          ?.user
                                          .value
                                          .status
                                          ?.val ??
                                      'label_online'.l10n,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                                const Spacer(),
                                Text(
                                  'label_a_of_b'.l10nfmt({
                                    'a': '${actualMembers.length}',
                                    'b': '${chat?.members.length}',
                                  }),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

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
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';

import '../controller.dart';
import '../../home/widget/avatar.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/themes.dart';

/// Builds a tile representation of the [CallController.chat].
class MobileChatWidget extends StatelessWidget {
  const MobileChatWidget(
    this.c, {
    Key? key,
  }) : super(key: key);

  /// Controller of an [OngoingCall] overlay.
  final CallController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Style style = Theme.of(context).extension<Style>()!;
      final RxChat? chat = c.chat.value;

      final Set<UserId> actualMembers =
          c.members.keys.map((k) => k.userId).toSet();

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
              onTap: () => c.openAddMember(context),
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
                                c.duration.value.hhMmSs(),
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
                                  c.chat.value?.members.values
                                          .firstWhereOrNull(
                                            (e) => e.id != c.me.id.userId,
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
                                    'b': '${c.chat.value?.members.length}',
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

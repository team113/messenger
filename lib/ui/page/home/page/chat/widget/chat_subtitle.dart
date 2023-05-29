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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// [Widget] which returns a header subtitle of the [Chat].
class ChatSubtitle extends StatelessWidget {
  const ChatSubtitle({
    super.key,
    required this.duration,
    required this.getUser,
    this.chat,
    this.me,
  });

  /// [RxChat] object that contains information on the chat being displayed,
  /// including ongoing call information and typing users.
  final RxChat? chat;

  /// ID of the person currently signed in to the chat.
  final UserId? me;

  /// [Duration] object that represents the duration of the chat.
  final Duration? duration;

  /// Returns an [User] from [UserService] by the provided id.
  final Future<RxUser?>? Function(UserId id) getUser;

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyle = Theme.of(context).textTheme.bodySmall;
    final Style style = Theme.of(context).extension<Style>()!;

    if (chat!.chat.value.ongoingCall != null) {
      final subtitle = StringBuffer();
      if (!context.isMobile) {
        subtitle
            .write('${'label_call_active'.l10n}${'space_vertical_space'.l10n}');
      }

      final Set<UserId> actualMembers =
          chat!.chat.value.ongoingCall!.members.map((k) => k.user.id).toSet();
      subtitle.write(
        'label_a_of_b'.l10nfmt(
          {'a': actualMembers.length, 'b': chat!.members.length},
        ),
      );

      if (duration != null) {
        subtitle.write(
          '${'space_vertical_space'.l10n}${duration?.hhMmSs()}',
        );
      }

      return Text(subtitle.toString(), style: textStyle);
    }

    bool isTyping = chat?.typingUsers.any((e) => e.id != me) == true;
    if (isTyping) {
      if (chat?.chat.value.isGroup == false) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'label_typing'.l10n,
              style: textStyle?.copyWith(color: style.colors.primary),
            ),
            const SizedBox(width: 3),
            const Padding(
              padding: EdgeInsets.only(bottom: 3),
              child: AnimatedTyping(),
            ),
          ],
        );
      }

      Iterable<String> typings = chat!.typingUsers
          .where((e) => e.id != me)
          .map((e) => e.name?.val ?? e.num.val);

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              typings.join('comma_space'.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle?.copyWith(color: style.colors.primary),
            ),
          ),
          const SizedBox(width: 3),
          const Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: AnimatedTyping(),
          ),
        ],
      );
    }

    if (chat!.chat.value.isGroup) {
      final String? subtitle = chat!.chat.value.getSubtitle();
      if (subtitle != null) {
        return Text(subtitle, style: textStyle);
      }
    } else if (chat!.chat.value.isDialog) {
      final ChatMember? partner =
          chat!.chat.value.members.firstWhereOrNull((u) => u.user.id != me);
      if (partner != null) {
        return Row(
          children: [
            if (chat?.chat.value.muted != null) ...[
              SvgImage.asset(
                'assets/icons/muted_dark.svg',
                width: 19.99 * 0.6,
                height: 15 * 0.6,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: FutureBuilder<RxUser?>(
                future: getUser(partner.user.id),
                builder: (_, snapshot) {
                  if (snapshot.data != null) {
                    final String? subtitle = chat!.chat.value
                        .getSubtitle(partner: snapshot.data!.user.value);

                    final UserTextStatus? status =
                        snapshot.data!.user.value.status;

                    if (status != null || subtitle != null) {
                      final StringBuffer buffer = StringBuffer(status ?? '');

                      if (status != null && subtitle != null) {
                        buffer.write('space_vertical_space'.l10n);
                      }

                      buffer.write(subtitle ?? '');

                      return Text(buffer.toString(), style: textStyle);
                    }

                    return const SizedBox();
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        );
      }
    }

    return const SizedBox();
  }
}

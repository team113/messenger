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
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/widget/svg/svg.dart';

/// [Widget] which returns a header subtitle of the chat.
class ChatSubtitle extends StatelessWidget {
  const ChatSubtitle({
    super.key,
    required this.rxChat,
    required this.test,
    this.text,
    this.subtitle,
    this.future,
    this.partner = true,
  });

  /// [RxChat] of this [ChatSubtitle].
  final RxChat? rxChat;

  /// [Text] to display in this [ChatSubtitle].
  final String? text;

  /// Indicator whether the chat is with a partner.
  final bool partner;

  /// Subtitle [Widget] of this [ChatSubtitle].
  final Widget? subtitle;

  /// Returns an [RxUser] by the provided id.
  final Future<RxUser?>? future;

  /// Callback, called for test some condition for a given user.
  final bool Function(User) test;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    final Chat chat = rxChat!.chat.value;

    if (chat.ongoingCall != null && subtitle != null) {
      return subtitle!;
    }

    if (rxChat?.typingUsers.any(test) == true) {
      if (!chat.isGroup) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'label_typing'.l10n,
              style: fonts.labelMedium!.copyWith(color: style.colors.primary),
            ),
            const SizedBox(width: 3),
            const Padding(
              padding: EdgeInsets.only(bottom: 3),
              child: AnimatedTyping(),
            ),
          ],
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (text != null)
            Flexible(
              child: Text(
                text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: fonts.labelMedium!.copyWith(color: style.colors.primary),
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

    if (chat.isGroup) {
      if (chat.getSubtitle() != null) {
        return Text(
          chat.getSubtitle()!,
          style: fonts.bodySmall!.copyWith(color: style.colors.secondary),
        );
      }
    } else if (chat.isDialog) {
      if (partner) {
        return Row(
          children: [
            if (chat.muted != null) ...[
              SvgImage.asset(
                'assets/icons/muted_dark.svg',
                width: 19.99 * 0.6,
                height: 15 * 0.6,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: FutureBuilder<RxUser?>(
                future: future,
                builder: (_, snapshot) {
                  if (snapshot.data != null) {
                    final String? subtitle =
                        chat.getSubtitle(partner: snapshot.data!.user.value);

                    final UserTextStatus? status =
                        snapshot.data!.user.value.status;

                    if (status != null || subtitle != null) {
                      final StringBuffer buffer = StringBuffer(status ?? '');

                      if (status != null && subtitle != null) {
                        buffer.write('space_vertical_space'.l10n);
                      }

                      buffer.write(subtitle ?? '');

                      return Text(
                        buffer.toString(),
                        style: fonts.bodySmall!.copyWith(
                          color: style.colors.secondary,
                        ),
                      );
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

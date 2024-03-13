// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';

import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';

/// Tile representing a the provided [chat] along with the [duration].
class ChatInfoCard extends StatelessWidget {
  const ChatInfoCard({
    super.key,
    this.duration,
    this.chat,
    this.subtitle,
    this.trailing,
    this.at,
    this.onTap,
  });

  /// [RxChat] to display.
  final RxChat? chat;

  /// Subtitle to display under the [chat].
  final String? subtitle;

  /// Trailing to add to this [ChatInfoCard].
  final String? trailing;

  /// [Duration] to display within this [ChatInfoCard].
  final Duration? duration;

  final PreciseDateTime? at;

  /// Callback, called when this [ChatInfoCard] is pressed.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: style.cardRadius,
          color: style.colors.transparent,
        ),
        child: Material(
          type: MaterialType.card,
          borderRadius: style.cardRadius,
          color: style.colors.onSecondaryOpacity50,
          child: InkWell(
            borderRadius: style.cardRadius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  AvatarWidget.fromRxChat(chat, radius: AvatarRadius.large),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat?.title ?? 'dot'.l10n * 3,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: style.fonts.big.regular.onPrimary,
                        ),
                        if (trailing != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            trailing!,
                            style: style.fonts.normal.regular.onPrimary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Column(
                    children: [
                      if (duration != null)
                        Text(
                          duration!.hhMmSs(),
                          style: style.fonts.normal.regular.onPrimary,
                        ),
                      if (duration != null && at != null)
                        const SizedBox(height: 5),
                      if (at != null)
                        Text(
                          at!.val.toLocal().short,
                          style: style.fonts.normal.regular.onPrimary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

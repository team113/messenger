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
import 'package:get/get.dart';

import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/avatar.dart';

/// Tile representing a chat.
class ChatInfoCard extends StatelessWidget {
  const ChatInfoCard({
    super.key,
    required this.callDuration,
    this.chat,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  /// [RxChat] call is happening in.
  final RxChat? chat;

  /// Subtitle of this [ChatInfoCard].
  final String? subtitle;

  /// Trailing of this [ChatInfoCard].
  final String? trailing;

  /// Duration of the call.
  final Rx<Duration> callDuration;

  /// Callback, called when this [ChatInfoCard] is pressed.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

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
                                style: fonts.headlineLarge!.copyWith(
                                  color: style.colors.onPrimary,
                                ),
                              ),
                            ),
                            Obx(() {
                              return Text(
                                callDuration.value.hhMmSs(),
                                style: fonts.labelLarge!.copyWith(
                                  color: style.colors.onPrimary,
                                ),
                              );
                            }),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: fonts.labelLarge!.copyWith(
                                    color: style.colors.onPrimary,
                                  ),
                                ),
                              const Spacer(),
                              if (trailing != null)
                                Text(
                                  trailing!,
                                  style: fonts.labelLarge!.copyWith(
                                    color: style.colors.onPrimary,
                                  ),
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
  }
}

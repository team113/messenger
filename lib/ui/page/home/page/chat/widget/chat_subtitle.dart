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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/widget/svg/svg.dart';

/// [Widget] which returns a header subtitle of the chat.
class ChatSubtitle extends StatelessWidget {
  const ChatSubtitle({
    super.key,
    this.text,
    this.child,
    this.subtitle,
    this.groupSubtitle,
    this.ongoingCall = true,
    this.isGroup = true,
    this.isDialog = false,
    this.isTyping = false,
    this.muted = false,
    this.partner = true,
  });

  /// [Text] to display in this [ChatSubtitle] when [isGroup] was `false`.
  final String? text;

  /// [Text] to display in this [ChatSubtitle] when [isGroup] was `true`.
  final String? groupSubtitle;

  /// Indicator whether a chat call is in progress.
  final bool ongoingCall;

  /// Indicator whether chat is a group.
  final bool isGroup;

  /// Indicator whether chat is a dialog.
  final bool isDialog;

  /// Indicator whether user currently typing in this chat.
  final bool isTyping;

  /// Indicator whether chat is muted.
  final bool muted;

  /// Indicator whether the chat is with a partner.
  final bool partner;

  /// [Widget] to display
  final Widget? child;

  /// Subtitle [Widget] of this [ChatSubtitle].
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    if (ongoingCall && subtitle != null) {
      return subtitle!;
    }

    if (isTyping) {
      if (!isGroup) {
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

    if (isGroup) {
      if (groupSubtitle != null) {
        return Text(
          groupSubtitle!,
          style: fonts.bodySmall!.copyWith(color: style.colors.secondary),
        );
      }
    } else if (isDialog) {
      if (partner) {
        return Row(
          children: [
            if (muted) ...[
              SvgImage.asset(
                'assets/icons/muted_dark.svg',
                width: 19.99 * 0.6,
                height: 15 * 0.6,
              ),
              const SizedBox(width: 5),
            ],
            if (child != null) child!,
          ],
        );
      }
    }

    return const SizedBox();
  }
}

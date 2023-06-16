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
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/util/platform_utils.dart';

import '/themes.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/widget/svg/svg.dart';

/// [Widget] which returns a header subtitle of the [Chat].
class ChatSubtitle extends StatelessWidget {
  const ChatSubtitle({
    super.key,
    required this.text,
    required this.child,
    this.groupSubtitle,
    this.label,
    this.duration,
    this.ongoingCall = true,
    this.isGroup = true,
    this.isDialog = false,
    this.isTyping = false,
    this.muted = false,
    this.partner = true,
  });

  ///
  final String text;

  ///
  final String? groupSubtitle;

  ///
  final String? label;

  ///
  final bool ongoingCall;

  ///
  final bool isGroup;

  ///
  final bool isDialog;

  ///
  final bool isTyping;

  ///
  final bool muted;

  ///
  final bool partner;

  ///
  final String? duration;

  ///
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    if (ongoingCall) {
      final subtitle = StringBuffer();
      if (!context.isMobile) {
        subtitle
            .write('${'label_call_active'.l10n}${'space_vertical_space'.l10n}');
      }

      subtitle.write(label);

      if (duration != null) {
        subtitle.write(
          '${'space_vertical_space'.l10n}$duration',
        );
      }

      return Text(
        subtitle.toString(),
        style: fonts.bodySmall!.copyWith(color: style.colors.secondary),
      );
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
          Flexible(
            child: Text(
              text,
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
            Flexible(child: child),
          ],
        );
      }
    }

    return const SizedBox();
  }
}

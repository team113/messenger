// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import '/domain/model/user_call_cover.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/svg/svg.dart';

/// Widget to build an [UserCallCover].
///
/// Displays an [UserAvatar] if [cover] is `null`.
///
/// Builds a background on `null` [cover] and [user].
class CallCoverWidget extends StatelessWidget {
  const CallCoverWidget(this.cover, {super.key, this.user, this.chat});

  /// [UserCallCover] to display.
  final UserCallCover? cover;

  /// [RxUser] to display [CallCoverWidget] of.
  final RxUser? user;

  /// [Chat] to display [CallCoverWidget] of.
  final RxChat? chat;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final UserCallCover? cover = this.cover ?? user?.user.value.callCover;

    return Stack(
      children: [
        if (cover == null)
          const SvgImage.asset(
            'assets/images/background_dark.svg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        if (user != null || chat != null)
          LayoutBuilder(
            builder: (context, constraints) {
              final String? title = chat?.title().initials() ?? user?.title();
              final int? color =
                  chat?.chat.value.colorDiscriminant(chat?.me).sum() ??
                  user?.user.value.num.val.sum();

              final Color gradient;

              if (color != null) {
                gradient = style
                    .colors
                    .userColors[color % style.colors.userColors.length];
              } else if (title != null) {
                gradient =
                    style.colors.userColors[(title.hashCode) %
                        style.colors.userColors.length];
              } else {
                gradient = style.colors.secondaryBackgroundLightest;
              }

              return Container(
                margin: const EdgeInsets.all(0.5),
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [gradient.lighten(), gradient],
                  ),
                ),
                child: Center(
                  child: Text(
                    title ?? '??',
                    textAlign: TextAlign.center,
                    style: style.fonts.normal.bold.onPrimary.copyWith(
                      fontSize:
                          (style.fonts.normal.bold.onPrimary.fontSize! *
                                  constraints.biggest.shortestSide /
                                  100)
                              .clamp(15, 108),
                    ),

                    // Disable the accessibility size settings for this [Text].
                    textScaler: const TextScaler.linear(1),
                  ),
                ),
              );
            },
          ),
        if (cover != null)
          RetryImage(
            cover.full.url,
            key: Key(cover.full.url),
            checksum: cover.full.checksum,
            thumbhash: cover.full.thumbhash,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            displayProgress: false,
          ),
      ],
    );
  }
}

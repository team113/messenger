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

import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/svg/svg.dart';

/// Widget to build an [UserCallCover].
///
/// Displays an [UserAvatar] if [cover] is `null`.
///
/// Builds a background on `null` [cover] and [user].
class CallCoverWidget extends StatelessWidget {
  const CallCoverWidget(this.cover, {Key? key, this.user}) : super(key: key);

  /// [UserCallCover] to display.
  final UserCallCover? cover;

  /// [User] this [UserCallCover] belongs to.
  final User? user;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (cover == null)
          SvgLoader.asset(
            'assets/images/background_dark.svg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        if (user != null)
          LayoutBuilder(builder: (context, constraints) {
            final String? title = user?.name?.val ?? user?.num.val;
            final int? color = user?.num.val.sum();

            final Color gradient;

            if (color != null) {
              gradient =
                  AvatarWidget.colors[color % AvatarWidget.colors.length];
            } else if (title != null) {
              gradient = AvatarWidget
                  .colors[(title.hashCode) % AvatarWidget.colors.length];
            } else {
              gradient = const Color(0xFF555555);
            }

            return Container(
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: (15 * constraints.biggest.shortestSide / 100)
                            .clamp(15, 108),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),

                  // Disable the accessibility size settings for this [Text].
                  textScaleFactor: 1,
                ),
              ),
            );
          }),
        if (cover != null)
          RetryImage(
            cover!.full.url,
            checksum: cover!.full.checksum,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            displayProgress: false,
          ),
      ],
    );
  }
}

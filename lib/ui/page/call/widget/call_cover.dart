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
        cover == null
            ? SvgLoader.asset(
                'assets/images/background_dark.svg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
            : Stack(
                children: [
                  RetryImage(
                    cover!.full,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color(0x55000000),
                  )
                ],
              ),
        if (user != null && cover == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AvatarWidget.fromUser(user, radius: 60),
            ),
          ),
      ],
    );
  }
}

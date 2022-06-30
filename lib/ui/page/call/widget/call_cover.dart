// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/config.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/svg/svg.dart';

/// Widget to build an [UserCallCover].
///
/// Builds a background on `null` [cover].
class CallCoverWidget extends StatelessWidget {
  const CallCoverWidget(
    this.cover, {
    Key? key,
    this.backdrop = false,
    this.user,
  }) : super(key: key);

  /// Call cover data object.
  final UserCallCover? cover;

  /// Indicator whether should be used single color background.
  final bool backdrop;

  /// [User] of this [CallCoverWidget].
  final User? user;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        cover == null
            ? backdrop
                ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color.fromARGB(255, 25, 37, 55),
                  )
                : SvgLoader.asset(
                    'assets/images/background_dark.svg',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
            : Stack(
                children: [
                  Image.network(
                    '${Config.url}:${Config.port}/files${cover?.full}',
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
        Container(
          margin: const EdgeInsets.all(0),
          child: ConditionalBackdropFilter(
            condition: backdrop,
            child: Container(),
          ),
        ),
      ],
    );
  }
}

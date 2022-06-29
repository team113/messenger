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
import 'package:get/get.dart';

import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/fluent/extension.dart';
import '/ui/page/call/widget/animated_dots.dart';
import '/ui/page/home/widget/avatar.dart';

/// [AvatarWidget] with caption and subtitle texts used to display
/// [ChatCall.caller] and [OngoingCall] state.
class CallTitle extends StatelessWidget {
  const CallTitle(
    this.me, {
    Key? key,
    this.chat,
    this.title,
    this.avatar,
    this.state,
    this.withDots = false,
  }) : super(key: key);

  /// [Chat] that contains the current [OngoingCall].
  final Chat? chat;

  /// Title of the [chat].
  final String? title;

  /// [UserId] of the current [MyUser].
  final UserId me;

  /// [Avatar] of the [chat].
  final Avatar? avatar;

  /// Optional state text.
  final String? state;

  /// Indicator whether [AnimatedDots] should be displayed near the [state] or
  /// not.
  ///
  /// Only meaningful if [state] is non-`null`.
  final bool withDots;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      maxLines: 1,
      softWrap: true,
      overflow: TextOverflow.ellipsis,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AvatarWidget.fromChat(
            chat,
            title,
            avatar,
            me,
            radius: 32,
            opacity: 0.8,
          ),
          const SizedBox(height: 16),
          Text(
            title ?? ('.'.td() * 3),
            style: context.textTheme.headline4?.copyWith(color: Colors.white),
          ),
          if (state != null) const SizedBox(height: 3),
          if (state != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (withDots) const SizedBox(width: 13),
                Text(
                  state!,
                  style:
                      context.textTheme.caption?.copyWith(color: Colors.white),
                ),
                if (withDots) const AnimatedDots(),
              ],
            ),
        ],
      ),
    );
  }
}

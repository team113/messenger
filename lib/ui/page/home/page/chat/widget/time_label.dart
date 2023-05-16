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
import 'package:intl/intl.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';

import '/themes.dart';
import 'swipeable_status.dart';

/// [Widget] which returns a centered [time] label.
class TimeLabel extends StatelessWidget {
  const TimeLabel(
    this.i, {
    super.key,
    required this.time,
    required this.stickyIndex,
    required this.showSticky,
    required this.animation,
  });

  /// Index of the element.
  final int i;

  /// [DateTime]  that represents the time value.
  final DateTime time;

  /// Sticky element index of a [FlutterListView] currently being visible.
  final RxnInt stickyIndex;

  /// Indicator whether sticky header should be visible or not.
  final RxBool showSticky;

  /// [AnimationController] of [SwipeableStatus]es.
  final AnimationController animation;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SwipeableStatus(
        animation: animation,
        padding: const EdgeInsets.only(right: 8),
        crossAxisAlignment: CrossAxisAlignment.center,
        swipeable: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(DateFormat('dd.MM.yy').format(time)),
        ),
        child: Obx(() {
          return AnimatedOpacity(
            key: Key('$i$time'),
            opacity: stickyIndex.value == i
                ? showSticky.isTrue
                    ? 1
                    : 0
                : 1,
            duration: const Duration(milliseconds: 250),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: style.systemMessageBorder,
                  color: style.systemMessageColor,
                ),
                child: Text(
                  time.toRelative(),
                  style: style.systemMessageStyle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

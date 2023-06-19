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
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '/themes.dart';
import 'current_position.dart';
import 'mute_button.dart';
import 'progress_bar.dart';

/// [AnimatedOpacity] which returns mobile design of a bottom controls bar.
class BottomControlBar extends StatelessWidget {
  const BottomControlBar({
    super.key,
    required this.controller,
    this.barHeight,
    this.hideStuff = true,
    this.onTap,
    this.onDragStart,
    this.onDragEnd,
  });

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// Height of the bottom controls bar.
  final double? barHeight;

  /// Indicator whether user interface should be visible or not.
  final bool hideStuff;

  /// Callback, called when [MuteButton] is tapped.
  final void Function()? onTap;

  ///
  final dynamic Function()? onDragStart;

  ///
  final dynamic Function()? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedOpacity(
      opacity: hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              style.colors.transparent,
              style.colors.onBackgroundOpacity40
            ],
          ),
        ),
        child: SafeArea(
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      CurrentPosition(controller: controller),
                      MuteButton(
                        controller: controller,
                        opacity: hideStuff ? 0.0 : 1.0,
                        barHeight: barHeight,
                        onTap: onTap,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(children: [
                      CustomProgressBar(
                        controller: controller,
                        onDragStart: onDragStart,
                        onDragEnd: onDragEnd,
                      )
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

// ignore_for_file: implementation_imports

import 'package:chewie/src/animated_play_pause.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '/themes.dart';

/// Returns the play/pause button.
class StyledPlayPauseButton extends StatelessWidget {
  const StyledPlayPauseButton({
    super.key,
    required this.controller,
    this.barHeight = 48.0 * 1.5,
    this.onTap,
  });

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// Height of the bottom controls bar.
  final double? barHeight;

  /// Callback, called when this [StyledPlayPauseButton] is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Transform.translate(
      offset: const Offset(0, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: barHeight,
          color: style.colors.transparent,
          child: RxBuilder((_) {
            return AnimatedPlayPause(
              size: 21,
              playing: controller.playerStatus.playing,
              color: style.colors.onPrimary,
            );
          }),
        ),
      ),
    );
  }
}

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

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import 'video_progress_bar.dart';
import '/themes.dart';

/// Custom-styled [ProgressBar].
class StyledProgressBar extends StatelessWidget {
  const StyledProgressBar({
    super.key,
    required this.controller,
    this.onDragStart,
    this.onDragEnd,
    this.drawShadow = true,
  });

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// Indicator whether a shadow should be drawn around this [ProgressBar].
  final bool drawShadow;

  /// Callback, called when progress drag started.
  final dynamic Function()? onDragStart;

  /// Callback, called when progress drag ended.
  final dynamic Function()? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Expanded(
      child: ProgressBar(
        controller,
        barHeight: 2,
        handleHeight: 6,
        drawShadow: drawShadow,
        onDragStart: onDragStart,
        onDragEnd: onDragEnd,
        colors: ChewieProgressColors(
          playedColor: style.colors.primary,
          handleColor: style.colors.primary,
          bufferedColor: style.colors.background.withOpacity(0.5),
          backgroundColor: style.colors.secondary.withOpacity(0.5),
        ),
      ),
    );
  }
}

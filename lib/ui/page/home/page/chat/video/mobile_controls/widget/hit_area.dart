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

import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:chewie/src/center_play_button.dart';

import '/themes.dart';

/// Hit area, which can be tapped to perform an action.
class HitArea extends StatelessWidget {
  const HitArea({
    super.key,
    required this.controller,
    this.onPressed,
    this.show = true,
  });

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// Indicator whether to show this [HitArea].
  final bool show;

  /// Callback, called whin this [HitArea] is tapped.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return RxBuilder((_) {
      final bool isFinished =
          controller.position.value >= controller.duration.value;

      return CenterPlayButton(
        backgroundColor: style.colors.onBackgroundOpacity13,
        iconColor: style.colors.onPrimary,
        isFinished: isFinished,
        isPlaying: controller.playerStatus.playing,
        show: show,
        onPressed: onPressed,
      );
    });
  }
}

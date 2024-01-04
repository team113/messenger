// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:media_kit_video/media_kit_video.dart';

import '/themes.dart';
import 'animated_play_pause.dart';

/// Centered [AnimatedPlayPause] displaying a state of the [controller].
class CenteredPlayPause extends StatelessWidget {
  const CenteredPlayPause(
    this.controller, {
    super.key,
    this.size = 48,
    this.onPressed,
    this.show = true,
  });

  /// [VideoController] controlling the [Video] player functionality.
  final VideoController controller;

  /// Size of this [CenteredPlayPause].
  final double size;

  /// Indicator whether to show this [CenteredPlayPause].
  final bool show;

  /// Callback, called when this [CenteredPlayPause] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return StreamBuilder(
      stream: controller.player.stream.completed,
      initialData: controller.player.state.completed,
      builder: (_, snapshot) {
        final bool isFinished = snapshot.data!;

        return Center(
          child: AnimatedOpacity(
            opacity: show ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: style.colors.onBackgroundOpacity13,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                iconSize: 32,
                icon: isFinished
                    ? Icon(Icons.replay, color: style.colors.onPrimary)
                    : AnimatedPlayPause(
                        controller.player.state.playing,
                        color: style.colors.onPrimary,
                      ),
                onPressed: onPressed,
              ),
            ),
          ),
        );
      },
    );
  }
}

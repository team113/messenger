// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

/// Custom-styled [AnimatedPlayPause] displaying a state of the [controller].
class CustomPlayPause extends StatelessWidget {
  const CustomPlayPause(this.controller, {super.key, this.height, this.onTap});

  /// [VideoController] controlling the [Video] player functionality.
  final VideoController controller;

  /// Height of this [CustomPlayPause].
  final double? height;

  /// Callback, called when this [CustomPlayPause] is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          color: style.colors.transparent,
          child: StreamBuilder(
            stream: controller.player.stream.playing,
            initialData: controller.player.state.playing,
            builder: (_, playing) {
              return AnimatedPlayPause(
                playing.data!,
                size: 21,
                color: style.colors.onPrimary,
              );
            },
          ),
        ),
      ),
    );
  }
}

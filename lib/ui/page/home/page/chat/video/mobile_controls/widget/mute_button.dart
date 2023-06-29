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

/// [Widget] which returns a mute/unmute button with a volume overlay above it.
class MuteButton extends StatelessWidget {
  const MuteButton({
    super.key,
    required this.controller,
    this.opacity = 1,
    this.height,
    this.onTap,
  });

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// Opacity of this [MuteButton].
  final double opacity;

  /// Height of this [MuteButton].
  final double? height;

  /// Callback, called when this [MuteButton] is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: height,
          margin: const EdgeInsets.only(right: 12.0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: RxBuilder((_) {
              return Icon(
                controller.volume.value > 0
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: style.colors.onPrimary,
                size: 18,
              );
            }),
          ),
        ),
      ),
    );
  }
}

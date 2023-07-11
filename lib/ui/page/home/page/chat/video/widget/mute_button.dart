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

/// Mute/unmute button with a volume overlay above it.
class MuteButton extends StatelessWidget {
  const MuteButton({
    super.key,
    required this.controller,
    this.height,
    this.onTap,
    this.padding,
    this.margin,
  });

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// Height of this [MuteButton].
  final double? height;

  final EdgeInsetsGeometry? padding;

  final EdgeInsetsGeometry? margin;

  /// Callback, called when this [MuteButton] is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GestureDetector(
      onTap: onTap,
      child: ClipRect(
        child: Container(
          height: height,
          padding: padding,
          margin: margin,
          child: RxBuilder((_) {
            return Icon(
              controller.volume.value > 0 ? Icons.volume_up : Icons.volume_off,
              color: style.colors.onPrimary,
              size: 18,
            );
          }),
        ),
      ),
    );
  }
}

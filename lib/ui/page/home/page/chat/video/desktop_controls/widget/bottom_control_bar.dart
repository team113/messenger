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

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '/themes.dart';
import '/ui/page/home/widget/animated_slider.dart';
import 'current_position.dart';
import 'expand_button.dart';
import 'mute_button.dart';
import 'play_pause_button.dart';
import 'progress_bar.dart';

/// [AnimatedSlider] which returns desktop design of a bottom controls bar.
class BottomControlBar extends StatelessWidget {
  const BottomControlBar({
    super.key,
    required this.controller,
    this.volumeKey,
    this.barHeight,
    this.onPlayPause,
    this.onMute,
    this.onFullscreen,
    this.onDragStart,
    this.onDragEnd,
    this.onEnter,
    this.isFullscreen = false,
    this.isOpen = true,
  });

  /// [GlobalKey] of the volume entry.
  final GlobalKey? volumeKey;

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// Height of the bottom controls bar.
  final double? barHeight;

  /// Indicator whether the [AnimatedSlider] should be visible or not.
  final bool? isOpen;

  /// Indicator whether this video is in fullscreen mode.
  final bool? isFullscreen;

  /// Callback, called when [StyledPlayPauseButton] is tapped.
  final void Function()? onPlayPause;

  /// Callback, called when [MuteButton] is tapped.
  final void Function()? onMute;

  /// Callback, called when [ExpandButton] is tapped.
  final void Function()? onFullscreen;

  /// Callback, called when progress drag started.
  final dynamic Function()? onDragStart;

  /// Callback, called when progress drag ended.
  final dynamic Function()? onDragEnd;

  ///
  final void Function(PointerEnterEvent)? onEnter;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedSlider(
      duration: const Duration(milliseconds: 300),
      isOpen: isOpen!,
      translate: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 32, right: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 32,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: style.colors.onBackgroundOpacity40,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 7),
                  StyledPlayPauseButton(
                    controller: controller,
                    barHeight: barHeight,
                    onTap: onPlayPause,
                  ),
                  const SizedBox(width: 12),
                  CurrentPosition(controller: controller),
                  const SizedBox(width: 12),
                  CustomProgressBar(
                    controller: controller,
                    onDragStart: onDragStart,
                    onDragEnd: onDragEnd,
                  ),
                  const SizedBox(width: 12),
                  MuteButton(
                    controller: controller,
                    volumeKey: volumeKey,
                    barHeight: barHeight,
                    onEnter: onEnter,
                    onTap: onMute,
                  ),
                  const SizedBox(width: 12),
                  ExpandButton(
                    isFullscreen: isFullscreen,
                    barHeight: barHeight,
                    onTap: onFullscreen,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

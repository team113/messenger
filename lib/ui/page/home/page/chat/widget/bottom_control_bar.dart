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

import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:chewie/src/animated_play_pause.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:chewie/src/progress_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/page/home/widget/animated_slider.dart';
import 'video_progress_bar.dart';

/// Returns the bottom controls bar.
class BottomControlBar extends StatelessWidget {
  const BottomControlBar({
    super.key,
    required this.controller,
    this.volumeKey,
    this.barHeight,
    this.playPause,
    this.onTap,
    this.onTap2,
    this.onDragStart,
    this.onDragEnd,
    this.onEnter,
    this.isFullscreen = false,
    this.isOpen = true,
  });

  ///
  final GlobalKey? volumeKey;

  ///
  final MeeduPlayerController controller;

  ///
  final double? barHeight;

  ///
  final bool? isOpen;

  ///
  final bool? isFullscreen;

  ///
  final void Function()? playPause;

  ///
  final void Function()? onTap;

  ///
  final void Function()? onTap2;

  ///
  final dynamic Function()? onDragStart;

  ///
  final dynamic Function()? onDragEnd;

  ///
  final void Function(PointerEnterEvent)? onEnter;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

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
                  _buildPlayPause(controller, context),
                  const SizedBox(width: 12),
                  _buildPosition(fonts.labelLarge!.color, context),
                  const SizedBox(width: 12),
                  _buildProgressBar(context),
                  const SizedBox(width: 12),
                  _buildMuteButton(controller, context),
                  const SizedBox(width: 12),
                  _buildExpandButton(context),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the play/pause button.
  Widget _buildPlayPause(
    MeeduPlayerController controller,
    BuildContext context,
  ) {
    final style = Theme.of(context).style;

    return Transform.translate(
      offset: const Offset(0, 0),
      child: GestureDetector(
        onTap: playPause,
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

  /// Returns the [Text] of the current video position.
  Widget _buildPosition(Color? iconColor, BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return RxBuilder((_) {
      final position = controller.position.value;
      final duration = controller.duration.value;

      return Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: fonts.headlineSmall!.copyWith(color: style.colors.onPrimary),
      );
    });
  }

  /// Returns the [VideoProgressBar] of the current video progression.
  Widget _buildProgressBar(BuildContext context) {
    final style = Theme.of(context).style;

    return Expanded(
      child: ProgressBar(
        controller,
        barHeight: 2,
        handleHeight: 6,
        drawShadow: false,
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

  /// Returns the mute/unmute button with a volume overlay above it.
  Widget _buildMuteButton(
    MeeduPlayerController controller,
    BuildContext context,
  ) {
    final style = Theme.of(context).style;

    return MouseRegion(
      onEnter: onEnter,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRect(
          child: SizedBox(
            key: volumeKey,
            height: barHeight,
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

  /// Returns the fullscreen toggling button.
  Widget _buildExpandButton(BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(
      () => GestureDetector(
        onTap: onTap2,
        child: SizedBox(
          height: barHeight,
          child: Center(
            child: Icon(
              isFullscreen! ? Icons.fullscreen_exit : Icons.fullscreen,
              color: style.colors.onPrimary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

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

import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:chewie/src/center_play_button.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:chewie/src/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '/themes.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/platform_utils.dart';
import 'video_progress_bar.dart';

/// Mobile video controls for a [Chewie] player.
class MobileControls extends StatefulWidget {
  const MobileControls({Key? key, required this.controller}) : super(key: key);

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  @override
  State<StatefulWidget> createState() => _MobileControlsState();
}

/// State of [MobileControls], used to control a video.
class _MobileControlsState extends State<MobileControls>
    with SingleTickerProviderStateMixin {
  /// Height of the bottom controls bar.
  final _barHeight = 48.0 * 1.5;

  /// Indicator whether user interface should be visible or not.
  bool _hideStuff = true;

  /// Latest volume value.
  double? _latestVolume;

  /// [Timer], used to hide user interface after a timeout.
  Timer? _hideTimer;

  /// Indicator whether the video progress bar is being dragged.
  bool _dragging = false;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return MouseRegion(
      onHover: PlatformUtils.isMobile ? null : (_) => _cancelAndRestartTimer(),
      child: GestureDetector(
        onTap: () {
          if (!_hideStuff) {
            setState(() => _hideStuff = true);
          } else {
            _cancelAndRestartTimer();
          }
        },
        child: Stack(
          children: [
            RxBuilder((_) {
              return widget.controller.isBuffering.value
                  ? const Center(child: CustomProgressIndicator())
                  : _buildHitArea();
            }),

            // Double tap to seek 10 seconds earlier.
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onDoubleTap: () {
                  widget.controller.seekTo(
                    widget.controller.position.value -
                        const Duration(seconds: 10),
                  );

                  if (!_hideStuff) {
                    _cancelAndRestartTimer();
                  }
                },
                child: Container(
                  color: style.colors.transparent,
                  width: (MediaQuery.of(context).size.width / 6).clamp(50, 250),
                  height: double.infinity,
                ),
              ),
            ),

            // Double tap to seek 10 seconds forward.
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onDoubleTap: () {
                  widget.controller.seekTo(
                    widget.controller.position.value +
                        const Duration(seconds: 10),
                  );

                  if (!_hideStuff) {
                    _cancelAndRestartTimer();
                  }
                },
                child: Container(
                  color: style.colors.transparent,
                  width: (MediaQuery.of(context).size.width / 6).clamp(50, 250),
                  height: double.infinity,
                ),
              ),
            ),

            // Bottom controls bar.
            IgnorePointer(
              ignoring: _hideStuff,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_buildBottomBar(context)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the bottom controls bar.
  AnimatedOpacity _buildBottomBar(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final iconColor = Theme.of(context).textTheme.labelLarge!.color;

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
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
            height: _barHeight,
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _buildPosition(iconColor),
                      _buildMuteButton(),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(children: [_buildProgressBar()]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the [Center]ed play/pause circular button.
  Widget _buildHitArea() {
    final Style style = Theme.of(context).extension<Style>()!;

    return RxBuilder((_) {
      final bool isFinished =
          widget.controller.position.value >= widget.controller.duration.value;

      return CenterPlayButton(
        backgroundColor: style.colors.onBackgroundOpacity13,
        iconColor: style.colors.onPrimary,
        isFinished: isFinished,
        isPlaying: widget.controller.playerStatus.playing,
        show: !_dragging && !_hideStuff,
        onPressed: _playPause,
      );
    });
  }

  /// Returns the mute/unmute button.
  GestureDetector _buildMuteButton() {
    final Style style = Theme.of(context).extension<Style>()!;

    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (widget.controller.volume.value == 0) {
          widget.controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = widget.controller.volume.value;
          widget.controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: _barHeight,
          margin: const EdgeInsets.only(right: 12.0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: RxBuilder((_) {
              return Icon(
                widget.controller.volume.value > 0
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

  /// Returns the [RichText] of the current video position.
  Widget _buildPosition(Color? iconColor) {
    final Style style = Theme.of(context).extension<Style>()!;

    return RxBuilder((_) {
      final position = widget.controller.position.value;
      final duration = widget.controller.duration.value;

      return RichText(
        text: TextSpan(
          text: '${formatDuration(position)} ',
          children: <InlineSpan>[
            TextSpan(
              text: '/ ${formatDuration(duration)}',
              style: TextStyle(
                fontSize: 14.0,
                color: style.colors.onPrimaryOpacity50,
                fontWeight: FontWeight.normal,
              ),
            )
          ],
          style: TextStyle(
            fontSize: 14.0,
            color: style.colors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    });
  }

  /// Returns the [VideoProgressBar] of the current video progression.
  Widget _buildProgressBar() {
    final Style style = Theme.of(context).extension<Style>()!;

    return Expanded(
      child: ProgressBar(
        widget.controller,
        barHeight: 2,
        handleHeight: 6,
        drawShadow: true,
        onDragStart: () {
          setState(() => _dragging = true);
          _hideTimer?.cancel();
        },
        onDragEnd: () {
          setState(() => _dragging = false);
          _startHideTimer();
        },
        colors: ChewieProgressColors(
          playedColor: style.colors.primary,
          handleColor: style.colors.primary,
          bufferedColor: style.colors.background.withOpacity(0.5),
          backgroundColor: style.colors.secondary.withOpacity(0.5),
        ),
      ),
    );
  }

  /// Toggles play and pause of the [_controller]. Starts video from the start
  /// if the playback is done.
  void _playPause() {
    final isFinished =
        widget.controller.position.value >= widget.controller.duration.value;

    if (widget.controller.playerStatus.playing) {
      _hideStuff = false;
      _hideTimer?.cancel();
      widget.controller.pause();
    } else {
      _cancelAndRestartTimer();

      if (isFinished) {
        widget.controller.seekTo(const Duration());
      }
      widget.controller.play();
    }

    setState(() {});
  }

  /// Cancels the [_hideTimer] and starts it again.
  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();
    setState(() => _hideStuff = false);
  }

  /// Starts the [_hideTimer].
  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() => _hideStuff = true);
    });
  }
}

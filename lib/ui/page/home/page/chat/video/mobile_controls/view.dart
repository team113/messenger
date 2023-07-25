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
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:get/get.dart';

import 'widget/rewind_indicator.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/video/widget/position.dart';
import '/ui/page/home/page/chat/video/widget/video_progress_bar.dart';
import 'widget/styled_play_pause.dart.dart';
import 'widget/volume_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/platform_utils.dart';

/// Mobile video controls for a [Chewie] player.
class MobileControls extends StatefulWidget {
  const MobileControls({super.key, required this.controller, this.barHeight});

  final barHeight;

  /// [Duration] to seek forward or backward for.
  static const Duration seekDuration = Duration(seconds: 5);

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  @override
  State<StatefulWidget> createState() => _MobileControlsState();
}

/// State of [MobileControls], used to control a video.
class _MobileControlsState extends State<MobileControls>
    with SingleTickerProviderStateMixin {
  /// Indicator whether user interface should be visible or not.
  bool _hideStuff = true;

  /// Latest volume value.
  double? _latestVolume;

  /// [Timer], used to hide user interface after a timeout.
  Timer? _hideTimer;

  /// Indicator whether the video progress bar is being dragged.
  bool _dragging = false;

  /// Overall seek forward [Duration].
  Duration _seekForwardDuration = Duration.zero;

  /// Overall seek backward [Duration].
  Duration _seekBackwardDuration = Duration.zero;

  /// [Timer] resetting the [_seekForwardDuration].
  Timer? _seekForwardTimer;

  /// [Timer] resetting the [_seekBackwardDuration].
  Timer? _seekBackwardTimer;

  /// Indicator whether seek forward indicator should be showed.
  bool _showSeekForward = false;

  /// Indicator whether seek backward indicator should be showed.
  bool _showSeekBackward = false;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

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
                  : StyledPlayPause(
                      controller: widget.controller,
                      show: !_dragging && !_hideStuff,
                      onPressed: _playPause,
                    );
            }),

            // Seek backward indicator.
            Align(
              alignment: const Alignment(-0.8, 0),
              child: RewindIndicator(
                seconds: _seekBackwardDuration.inSeconds,
                forward: false,
                opacity:
                    _showSeekBackward && _seekBackwardDuration.inSeconds > 0
                        ? 1
                        : 0,
              ),
            ),

            // Seek forward indicator.
            Align(
              alignment: const Alignment(0.8, 0),
              child: RewindIndicator(
                seconds: _seekForwardDuration.inSeconds,
                forward: true,
                opacity: _showSeekForward && _seekForwardDuration.inSeconds > 0
                    ? 1
                    : 0,
              ),
            ),

            // Double tap to [_seekBackward].
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onDoubleTap: _seekBackward,
                child: Container(
                  color: style.colors.transparent,
                  width: MediaQuery.of(context).size.width / 4,
                  height: double.infinity,
                ),
              ),
            ),

            // Double tap to [_seekForward].
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onDoubleTap: _seekForward,
                child: Container(
                  color: style.colors.transparent,
                  width: MediaQuery.of(context).size.width / 4,
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
    final style = Theme.of(context).style;

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
              style.colors.onBackgroundOpacity40,
            ],
          ),
        ),
        child: SafeArea(
          child: Container(
            height: widget.barHeight,
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      CurrentPosition(controller: widget.controller),
                      VolumeButton(
                        controller: widget.controller,
                        height: widget.barHeight,
                        onTap: () {
                          _cancelAndRestartTimer();

                          if (widget.controller.volume.value == 0) {
                            widget.controller.setVolume(_latestVolume ?? 0.5);
                          } else {
                            _latestVolume = widget.controller.volume.value;
                            widget.controller.setVolume(0.0);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ProgressBar(
                            widget.controller,
                            drawShadow: false,
                            onDragStart: () {
                              setState(() => _dragging = true);
                              _hideTimer?.cancel();
                            },
                            onDragEnd: () {
                              setState(() => _dragging = false);
                              _startHideTimer();
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  /// Seeks forward for the [MobileControls.seekDuration].
  void _seekForward() {
    if (widget.controller.position.value >= widget.controller.duration.value) {
      return;
    }

    _hideSeekBackward(timeout: Duration.zero);
    _seekForwardDuration += Duration(
      microseconds: (widget.controller.duration.value.inMicroseconds -
              widget.controller.position.value.inMicroseconds)
          .clamp(0, MobileControls.seekDuration.inMicroseconds),
    );
    _showSeekForward = true;

    widget.controller.seekTo(
      widget.controller.position.value + MobileControls.seekDuration,
    );

    if (!_hideStuff) {
      _cancelAndRestartTimer();
    }

    if (mounted) {
      setState(() {});
    }

    _hideSeekForward();
  }

  /// Hides the seek forward indicator.
  void _hideSeekForward({Duration timeout = const Duration(seconds: 1)}) {
    _seekForwardTimer?.cancel();
    _seekForwardTimer = Timer(
      timeout,
      () async {
        if (mounted) {
          setState(() => _showSeekForward = false);
        }

        await Future.delayed(200.milliseconds);
        if (!_showSeekForward) {
          _seekForwardDuration = Duration.zero;
        }
      },
    );
  }

  /// Seeks backward for the [MobileControls.seekDuration].
  void _seekBackward() {
    if (widget.controller.duration.value == Duration.zero) {
      return;
    }

    _hideSeekForward(timeout: Duration.zero);
    _seekBackwardDuration += Duration(
      microseconds: widget.controller.position.value.inMicroseconds
          .clamp(0, MobileControls.seekDuration.inMicroseconds),
    );
    _showSeekBackward = true;

    widget.controller.seekTo(
      widget.controller.position.value - MobileControls.seekDuration,
    );

    if (!_hideStuff) {
      _cancelAndRestartTimer();
    }

    if (mounted) {
      setState(() {});
    }

    _hideSeekBackward();
  }

  /// Hides the seek backward indicator.
  void _hideSeekBackward({Duration timeout = const Duration(seconds: 1)}) {
    _seekBackwardTimer?.cancel();
    _seekBackwardTimer = Timer(
      timeout,
      () async {
        if (mounted) {
          setState(() => _showSeekBackward = false);
        }

        await Future.delayed(200.milliseconds);
        if (!_showSeekBackward) {
          _seekBackwardDuration = Duration.zero;
        }
      },
    );
  }
}

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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '/themes.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/safe_area/safe_area.dart';
import '/util/platform_utils.dart';
import 'centered_play_pause.dart';
import 'position.dart';
import 'rewind_indicator.dart';
import 'video_progress_bar.dart';
import 'volume_button.dart';

/// Mobile video controls for a [VideoView] player.
class MobileControls extends StatefulWidget {
  const MobileControls(this.controller, {super.key, this.barHeight});

  /// [VideoController] controlling the [Video] player functionality.
  final VideoController controller;

  /// Height of the bottom controls bar.
  final double? barHeight;

  /// [Duration] to seek forward or backward for.
  static const Duration seekDuration = Duration(seconds: 5);

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

    // Toggles the [_hideStuff].
    void toggleStuff() {
      if (!_hideStuff) {
        setState(() => _hideStuff = true);
      } else {
        _cancelAndRestartTimer();
      }
    }

    return MouseRegion(
      onHover: PlatformUtils.isMobile ? null : (_) => _cancelAndRestartTimer(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Shows and hides the interface.
          GestureDetector(
            onTap: toggleStuff,
            child: Container(
              color: style.colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          StreamBuilder(
            stream: widget.controller.player.stream.buffering,
            initialData: widget.controller.player.state.buffering,
            builder: (_, buffering) {
              return buffering.data!
                  ? const Center(child: CustomProgressIndicator())
                  : CenteredPlayPause(
                      widget.controller,
                      size: 56,
                      show: !_dragging && !_hideStuff,
                      onPressed: _playPause,
                    );
            },
          ),

          // Seek backward indicator.
          Align(
            alignment: const Alignment(-0.8, 0),
            child: IgnorePointer(
              child: RewindIndicator(
                seconds: _seekBackwardDuration.inSeconds,
                forward: false,
                opacity:
                    _showSeekBackward && _seekBackwardDuration.inSeconds > 0
                        ? 1
                        : 0,
              ),
            ),
          ),

          // Seek forward indicator.
          Align(
            alignment: const Alignment(0.8, 0),
            child: IgnorePointer(
              child: RewindIndicator(
                seconds: _seekForwardDuration.inSeconds,
                forward: true,
                opacity: _showSeekForward && _seekForwardDuration.inSeconds > 0
                    ? 1
                    : 0,
              ),
            ),
          ),

          // Double tap to [_seekBackward].
          Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: toggleStuff,
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
              onTap: toggleStuff,
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
        child: CustomSafeArea(
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
                      CurrentPosition(widget.controller),
                      VolumeButton(
                        widget.controller,
                        height: widget.barHeight,
                        margin: const EdgeInsets.only(right: 12.0),
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          right: 8.0,
                        ),
                        onTap: () {
                          _cancelAndRestartTimer();

                          if (widget.controller.player.state.volume == 0) {
                            widget.controller.player
                                .setVolume(_latestVolume ?? 0.5);
                          } else {
                            _latestVolume =
                                widget.controller.player.state.volume;
                            widget.controller.player.setVolume(0.0);
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
    final isFinished = widget.controller.player.state.position >=
        widget.controller.player.state.duration;

    if (widget.controller.player.state.playing) {
      _hideStuff = false;
      _hideTimer?.cancel();
      widget.controller.player.pause();
    } else {
      _cancelAndRestartTimer();

      if (isFinished) {
        widget.controller.player.seek(const Duration());
      }
      widget.controller.player.play();
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
    if (widget.controller.player.state.position >=
        widget.controller.player.state.duration) {
      return;
    }

    _hideSeekBackward(timeout: Duration.zero);
    _seekForwardDuration += Duration(
      microseconds: (widget.controller.player.state.duration.inMicroseconds -
              widget.controller.player.state.position.inMicroseconds)
          .clamp(0, MobileControls.seekDuration.inMicroseconds),
    );
    _showSeekForward = true;

    widget.controller.player.seek(
      widget.controller.player.state.position + MobileControls.seekDuration,
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
    if (widget.controller.player.state.duration == Duration.zero) {
      return;
    }

    _hideSeekForward(timeout: Duration.zero);
    _seekBackwardDuration += Duration(
      microseconds: widget.controller.player.state.position.inMicroseconds
          .clamp(0, MobileControls.seekDuration.inMicroseconds),
    );
    _showSeekBackward = true;

    widget.controller.player.seek(
      widget.controller.player.state.position - MobileControls.seekDuration,
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

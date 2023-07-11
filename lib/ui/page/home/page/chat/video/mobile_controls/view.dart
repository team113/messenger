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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '../widget/circular_control_button.dart';
import '/themes.dart';
import 'widget/bottom_control_bar.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/platform_utils.dart';

/// Mobile video controls for a [MeeduVideoPlayer].
class MobileControlsView extends StatefulWidget {
  const MobileControlsView({
    super.key,
    required this.controller,
    this.barHeight,
  });

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// Height of the bottom controls bar.
  final double? barHeight;

  @override
  State<StatefulWidget> createState() => _MobileControlsState();
}

/// State of [MobileControlsView], used to control a video.
class _MobileControlsState extends State<MobileControlsView>
    with SingleTickerProviderStateMixin {
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
                  : CircularControlButton(
                      controller: widget.controller,
                      show: !_dragging && !_hideStuff,
                      onPressed: _playPause,
                    );
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
                children: [
                  BottomControlBar(
                    controller: widget.controller,
                    barHeight: widget.barHeight,
                    hideStuff: _hideStuff,
                    onMute: () {
                      _cancelAndRestartTimer();

                      if (widget.controller.volume.value == 0) {
                        widget.controller.setVolume(_latestVolume ?? 0.5);
                      } else {
                        _latestVolume = widget.controller.volume.value;
                        widget.controller.setVolume(0.0);
                      }
                    },
                    onDragStart: () {
                      setState(() => _dragging = true);
                      _hideTimer?.cancel();
                    },
                    onDragEnd: () {
                      setState(() => _dragging = false);
                      _startHideTimer();
                    },
                  )
                ],
              ),
            ),
          ],
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

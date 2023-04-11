// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
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
import 'package:video_player/video_player.dart';

import '/ui/widget/progress_indicator.dart';
import '/util/platform_utils.dart';

/// Mobile video controls for a [Chewie] player.
class MobileControls extends StatefulWidget {
  const MobileControls({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MobileControlsState();
}

/// State of [MobileControls], used to control a video.
class _MobileControlsState extends State<MobileControls>
    with SingleTickerProviderStateMixin {
  /// Height of the bottom controls bar.
  final _barHeight = 48.0 * 1.5;

  /// [VideoPlayerController] controlling the video playback.
  late VideoPlayerController _controller;

  /// [ChewieController] controlling the [Chewie] functionality.
  late ChewieController _chewieController;

  /// [ChewieController], previously assigned to the [_chewieController].
  ChewieController? _oldController;

  /// Indicator whether user interface should be visible or not.
  bool _hideStuff = true;

  /// Latest [VideoPlayerValue] value.
  late VideoPlayerValue _latestValue;

  /// Latest volume value.
  double? _latestVolume;

  /// [Timer], used to hide user interface after a timeout.
  Timer? _hideTimer;

  /// [Timer], used to hide user interface on [_initialize].
  Timer? _initTimer;

  /// [Timer], used to show user interface for a while after fullscreen toggle.
  Timer? _showAfterExpandCollapseTimer;

  /// Indicator whether the video progress bar is being dragged.
  final bool _dragging = false;

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _chewieController = ChewieController.of(context);
    _controller = _chewieController.videoPlayerController;

    if (_oldController != _chewieController) {
      _oldController = _chewieController;
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return _chewieController.errorBuilder?.call(
            context,
            _chewieController.videoPlayerController.value.errorDescription!,
          ) ??
          const Center(child: Icon(Icons.error, color: Colors.white, size: 42));
    }

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
            _latestValue.isBuffering
                ? const Center(child: CustomProgressIndicator())
                : _BuildHitArea(
                    latestValue: _latestValue,
                    controller: _controller,
                    dragging: _dragging,
                    hideStuff: _hideStuff,
                    playPause: _playPause,
                  ),

            // Bottom controls bar.
            IgnorePointer(
              ignoring: _hideStuff,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _BuildBottomBar(
                    latestValue: _latestValue,
                    latestVolume: _latestVolume,
                    hideStuff: _hideStuff,
                    barHeight: _barHeight,
                    controller: _controller,
                    dragging: _dragging,
                    hideTimer: _hideTimer,
                    chewieController: _chewieController,
                    startHideTimer: _startHideTimer,
                    cancelAndRestartTimer: _cancelAndRestartTimer,
                  )
                ],
              ),
            ),

            // Double tap to seek 10 seconds earlier.
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onDoubleTap: () {
                  _chewieController.seekTo(
                    _chewieController.videoPlayerController.value.position -
                        const Duration(seconds: 10),
                  );

                  if (!_hideStuff) {
                    _cancelAndRestartTimer();
                  }
                },
                child: Container(
                  color: Colors.transparent,
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
                  _chewieController.seekTo(
                    _chewieController.videoPlayerController.value.position +
                        const Duration(seconds: 10),
                  );

                  if (!_hideStuff) {
                    _cancelAndRestartTimer();
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  width: (MediaQuery.of(context).size.width / 6).clamp(50, 250),
                  height: double.infinity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Initializes these [MobileControls].
  Future<void> _initialize() async {
    _controller.addListener(_updateState);
    _updateState();

    if (_controller.value.isPlaying || _chewieController.autoPlay) {
      _startHideTimer();
    }

    if (_chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() => _hideStuff = false);
      });
    }
  }

  /// Disposes these [MobileControls].
  void _dispose() {
    _controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  /// Toggles play and pause of the [_controller]. Starts video from the start
  /// if the playback is done.
  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    if (_controller.value.isPlaying) {
      _hideStuff = false;
      _hideTimer?.cancel();
      _controller.pause();
    } else {
      _cancelAndRestartTimer();

      if (!_controller.value.isInitialized) {
        _controller.initialize().then((_) {
          _controller.play();
        });
      } else {
        if (isFinished) {
          _controller.seekTo(const Duration());
        }
        _controller.play();
      }
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

  /// Invokes [setState] with a new [_latestValue] if [mounted].
  void _updateState() {
    if (!mounted) return;
    setState(() => _latestValue = _controller.value);
  }
}

/// Returns the [Center]ed play/pause circular button.
class _BuildHitArea extends StatelessWidget {
  final VideoPlayerValue latestValue;
  final VideoPlayerController controller;
  final bool dragging;
  final bool hideStuff;
  final void Function()? playPause;
  const _BuildHitArea({
    Key? key,
    required this.latestValue,
    required this.controller,
    required this.dragging,
    required this.hideStuff,
    required this.playPause,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isFinished = latestValue.position >= latestValue.duration;
    return CenterPlayButton(
      backgroundColor: Colors.black54,
      iconColor: Colors.white,
      isFinished: isFinished,
      isPlaying: controller.value.isPlaying,
      show: !dragging && !hideStuff,
      onPressed: playPause,
    );
  }
}

/// Returns the [RichText] of the current video position.
class _BuildPosition extends StatelessWidget {
  final Color? iconColor;
  final VideoPlayerValue latestValue;
  const _BuildPosition({
    Key? key,
    required this.iconColor,
    required this.latestValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final position = latestValue.position;
    final duration = latestValue.duration;

    return RichText(
      text: TextSpan(
        text: '${formatDuration(position)} ',
        children: <InlineSpan>[
          TextSpan(
            text: '/ ${formatDuration(duration)}',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.white.withOpacity(.75),
              fontWeight: FontWeight.normal,
            ),
          )
        ],
        style: const TextStyle(
          fontSize: 14.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Returns the mute/unmute button.
class _BuildMuteButton extends StatelessWidget {
  final VideoPlayerValue latestValue;

  /// Latest volume value.
  double? latestVolume;
  final VideoPlayerController controller;
  final bool hideStuff;
  final double barHeight;
  final void Function()? cancelAndRestartTimer;
  _BuildMuteButton({
    Key? key,
    required this.latestValue,
    required this.latestVolume,
    required this.controller,
    required this.hideStuff,
    required this.barHeight,
    required this.cancelAndRestartTimer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        cancelAndRestartTimer;

        if (latestValue.volume == 0) {
          controller.setVolume(latestVolume ?? 0.5);
        } else {
          latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          margin: const EdgeInsets.only(right: 12.0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              latestValue.volume > 0 ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns the [VideoProgressBar] of the current video progression.
class _BuildProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  bool dragging;
  final Timer? hideTimer;
  final void Function()? startHideTimer;
  final ChewieController chewieController;

  _BuildProgressBar({
    Key? key,
    required this.controller,
    required this.dragging,
    required this.hideTimer,
    required this.startHideTimer,
    required this.chewieController,
  }) : super(key: key);

  @override
  State<_BuildProgressBar> createState() => _BuildProgressBarState();
}

class _BuildProgressBarState extends State<_BuildProgressBar> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: VideoProgressBar(
        widget.controller,
        barHeight: 2,
        handleHeight: 6,
        drawShadow: true,
        onDragStart: () {
          setState(() => widget.dragging = true);
          widget.hideTimer?.cancel();
        },
        onDragEnd: () {
          setState(() => widget.dragging = false);
          widget.startHideTimer;
        },
        colors: widget.chewieController.materialProgressColors ??
            ChewieProgressColors(
              playedColor: Theme.of(context).colorScheme.secondary,
              handleColor: Theme.of(context).colorScheme.secondary,
              bufferedColor:
                  Theme.of(context).colorScheme.background.withOpacity(0.5),
              backgroundColor: Theme.of(context).disabledColor.withOpacity(.5),
            ),
      ),
    );
  }
}

/// Returns the bottom controls bar.
class _BuildBottomBar extends StatelessWidget {
  final VideoPlayerValue latestValue;

  /// Latest volume value.
  final double? latestVolume;
  final bool hideStuff;
  final double barHeight;
  final VideoPlayerController controller;
  final bool dragging;
  final Timer? hideTimer;
  final ChewieController chewieController;
  final void Function()? startHideTimer;
  final void Function()? cancelAndRestartTimer;

  const _BuildBottomBar({
    Key? key,
    required this.latestValue,
    required this.latestVolume,
    required this.hideStuff,
    required this.barHeight,
    required this.controller,
    required this.dragging,
    required this.hideTimer,
    required this.chewieController,
    required this.startHideTimer,
    required this.cancelAndRestartTimer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.labelLarge!.color;

    return AnimatedOpacity(
      opacity: hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0x66000000)],
          ),
        ),
        child: SafeArea(
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      chewieController.isLive
                          ? const Expanded(child: Text('LIVE'))
                          : _BuildPosition(
                              iconColor: iconColor,
                              latestValue: latestValue,
                            ),
                      _BuildMuteButton(
                        latestValue: latestValue,
                        latestVolume: latestVolume,
                        controller: controller,
                        hideStuff: hideStuff,
                        barHeight: barHeight,
                        cancelAndRestartTimer: cancelAndRestartTimer,
                      ),
                    ],
                  ),
                ),
                if (!chewieController.isLive)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(children: [
                        _BuildProgressBar(
                          controller: controller,
                          dragging: dragging,
                          hideTimer: hideTimer,
                          startHideTimer: startHideTimer,
                          chewieController: chewieController,
                        )
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:chewie/src/animated_play_pause.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/widget/progress_indicator.dart';
import 'video_progress_bar.dart';
import 'volume_bar.dart';

/// Desktop video controls for a [Chewie] player.
class DesktopControls extends StatefulWidget {
  const DesktopControls({
    super.key,
    required this.controller,
    this.onClose,
    this.toggleFullscreen,
    this.isFullscreen,
    this.showInterfaceFor,
    this.size,
  });

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// Callback, called when a close video action is fired.
  final VoidCallback? onClose;

  /// Callback, called when a toggle fullscreen action is fired.
  final VoidCallback? toggleFullscreen;

  /// Reactive indicator of whether this video is in fullscreen mode.
  final RxBool? isFullscreen;

  /// [Duration] to initially show an user interface for.
  final Duration? showInterfaceFor;

  /// [Size] of the video these [DesktopControls] are used for.
  final Size? size;

  @override
  State<StatefulWidget> createState() => _DesktopControlsState();
}

/// State of [DesktopControls], used to control a video.
class _DesktopControlsState extends State<DesktopControls>
    with SingleTickerProviderStateMixin {
  /// Height of the bottom controls bar.
  final _barHeight = 48.0 * 1.5;

  /// Indicator whether user interface should be hidden or not.
  bool _hideStuff = true;

  /// Indicator whether user interface should be visible or not.
  bool _showInterface = true;

  /// Indicator whether the bottom controls bar should be visible or not.
  bool _showBottomBar = false;

  /// [GlobalKey] of the [_volumeEntry].
  final GlobalKey _volumeKey = GlobalKey();

  /// [OverlayEntry] of the volume popup bar.
  OverlayEntry? _volumeEntry;

  /// Latest volume value.
  double? _latestVolume;

  /// [Timer] for hiding the user interface after a timeout.
  Timer? _hideTimer;

  /// [Timer] for toggling the [_showInterface] after a timeout.
  Timer? _interfaceTimer;

  /// [Timer] for toggling the [_showBottomBar] after a timeout.
  Timer? _bottomBarTimer;

  /// [Timer] for showing user interface for a while after fullscreen toggle.
  Timer? _showAfterExpandCollapseTimer;

  /// [StreamSubscription] to the [MeeduPlayerController.playerStatus] changes.
  StreamSubscription? _statusSubscription;

  /// Indicator whether the video or volume progress bar is being dragged.
  bool _dragging = false;

  @override
  void initState() {
    _statusSubscription =
        widget.controller.playerStatus.status.stream.listen((event) {
      if (event == PlayerStatus.paused) {
        _startInterfaceTimer(3.seconds);
      }
    });

    Future.delayed(
      Duration.zero,
      () => _startInterfaceTimer(widget.showInterfaceFor),
    );
    super.initState();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _hideTimer?.cancel();
    _interfaceTimer?.cancel();
    _bottomBarTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
    _volumeEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => _cancelAndRestartTimer(),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () => _cancelAndRestartTimer(),
        child: Stack(
          children: [
            // Closes the video on a tap outside [AspectRatio].
            GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: widget.onClose,
              child: Center(
                child: SizedBox.fromSize(
                  size: widget.size,
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (e) {
                      if (e.buttons & kPrimaryButton != 0 &&
                          _volumeEntry == null) {
                        _playPause();
                      }
                    },
                    // Double tap inside [AspectRatio] toggles fullscreen.
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {},
                      onDoubleTap: _onExpandCollapse,
                      // Required for the [GestureDetector]s to take the full
                      // width and height.
                      child: const SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Play/pause button.
            RxBuilder((_) {
              return widget.controller.isBuffering.value
                  ? const Center(child: CustomProgressIndicator())
                  : HitArea(
                      controller: widget.controller,
                      opacity: !_dragging && !_hideStuff || _showInterface
                          ? 1.0
                          : 0.0,
                      onPressed: _playPause,
                    );
            }),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildBottomBar(context)],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: MouseRegion(
                opaque: false,
                onEnter: (d) {
                  if (mounted) {
                    setState(() => _showBottomBar = true);
                  }
                },
                onExit: (d) {
                  if (mounted) {
                    setState(() => _showBottomBar = false);
                    if (!_dragging) {
                      _volumeEntry?.remove();
                      _volumeEntry = null;
                    }
                  }
                },
                child: SizedBox(
                  width: double.infinity,
                  height: _volumeEntry == null ? 40 : 40 + 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the bottom controls bar.
  Widget _buildBottomBar(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedSlider(
      duration: const Duration(milliseconds: 300),
      isOpen: _showBottomBar || _showInterface || _dragging,
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
                  CustomPlayPause(
                    controller: widget.controller,
                    height: _barHeight,
                    onTap: _playPause,
                  ),
                  const SizedBox(width: 12),
                  PositionWidget(controller: widget.controller),
                  const SizedBox(width: 12),
                  CustomProgressBar(
                    controller: widget.controller,
                    onDragStart: () {
                      setState(() => _dragging = true);
                      _hideTimer?.cancel();
                    },
                    onDragEnd: () {
                      setState(() => _dragging = false);
                      _startHideTimer();
                    },
                  ),
                  const SizedBox(width: 12),
                  MuteButton(
                    key: _volumeKey,
                    controller: widget.controller,
                    height: _barHeight,
                    onTap: () {
                      _cancelAndRestartTimer();
                      if (widget.controller.volume.value == 0) {
                        widget.controller.setVolume(_latestVolume ?? 0.5);
                      } else {
                        _latestVolume = widget.controller.volume.value;
                        widget.controller.setVolume(0.0);
                      }
                    },
                    onEnter: (_) {
                      if (mounted && _volumeEntry == null) {
                        Offset offset = Offset.zero;
                        final keyContext = _volumeKey.currentContext;
                        if (keyContext != null) {
                          final box =
                              keyContext.findRenderObject() as RenderBox;
                          offset = box.localToGlobal(Offset.zero);
                        }

                        _volumeEntry = OverlayEntry(
                            builder: (_) => _volumeOverlay(offset));
                        Overlay.of(context, rootOverlay: true)
                            .insert(_volumeEntry!);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  ExpandButton(
                    height: _barHeight,
                    isFullscreen: widget.isFullscreen?.value == true,
                    onTap: _onExpandCollapse,
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

  /// Returns the [Center]ed play/pause circular button.
  // Widget _buildHitArea() {
  //   final style = Theme.of(context).style;

  //   return RxBuilder((_) {
  //     final bool isFinished =
  //         widget.controller.position.value >= widget.controller.duration.value;

  //     return Center(
  //       child: AnimatedSwitcher(
  //         duration: const Duration(milliseconds: 200),
  //         child: widget.controller.playerStatus.playing
  //             ? Container()
  //             : AnimatedOpacity(
  //                 opacity:
  //                     !_dragging && !_hideStuff || _showInterface ? 1.0 : 0.0,
  //                 duration: const Duration(milliseconds: 300),
  //                 child: Container(
  //                   width: 48,
  //                   height: 48,
  //                   decoration: BoxDecoration(
  //                     color: style.colors.onBackgroundOpacity13,
  //                     shape: BoxShape.circle,
  //                   ),
  //                   child: IconButton(
  //                     iconSize: 32,
  //                     icon: isFinished
  //                         ? Icon(Icons.replay, color: style.colors.onPrimary)
  //                         : AnimatedPlayPause(
  //                             color: style.colors.onPrimary,
  //                             playing: widget.controller.playerStatus.playing,
  //                           ),
  //                     onPressed: _playPause,
  //                   ),
  //                 ),
  //               ),
  //       ),
  //     );
  //   });
  // }

  /// Returns the [_volumeEntry] overlay.
  Widget _volumeOverlay(Offset offset) {
    final style = Theme.of(context).style;

    return Stack(
      children: [
        Positioned(
          left: offset.dx - 6,
          bottom: 10,
          child: MouseRegion(
            opaque: false,
            onExit: (d) {
              if (mounted && !_dragging) {
                _volumeEntry?.remove();
                _volumeEntry = null;
                setState(() {});
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: 15,
                        height: 80,
                        decoration: BoxDecoration(
                          color: style.colors.onBackgroundOpacity40,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: VideoVolumeBar(
                                widget.controller,
                                onDragStart: () {
                                  setState(() => _dragging = true);
                                },
                                onDragEnd: () {
                                  if (!_showBottomBar) {
                                    _volumeEntry?.remove();
                                    _volumeEntry = null;
                                  }
                                  setState(() => _dragging = false);
                                },
                                colors: ChewieProgressColors(
                                  playedColor: style.colors.primary,
                                  handleColor: style.colors.primary,
                                  bufferedColor:
                                      style.colors.background.withOpacity(0.5),
                                  backgroundColor:
                                      style.colors.secondary.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 27),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Invokes a fullscreen toggle action.
  void _onExpandCollapse() {
    widget.toggleFullscreen?.call();
    _volumeEntry?.remove();
    _volumeEntry = null;

    _showAfterExpandCollapseTimer = Timer(
      const Duration(milliseconds: 300),
      () => setState(_cancelAndRestartTimer),
    );

    setState(() => _hideStuff = true);
  }

  /// Toggles play and pause of a [_controller]. Starts video from the start if
  /// the playback is done.
  void _playPause() {
    final isFinished =
        widget.controller.position.value >= widget.controller.duration.value;

    if (widget.controller.playerStatus.playing) {
      _cancelAndRestartTimer();
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

  /// Starts the [_interfaceTimer].
  void _startInterfaceTimer([Duration? duration]) {
    setState(() => _showInterface = true);
    _interfaceTimer?.cancel();
    _interfaceTimer = Timer(duration ?? 1.seconds, () {
      if (mounted) {
        setState(() => _showInterface = false);
      }
    });
  }

  /// Starts the [_hideTimer].
  void _startHideTimer([Duration? duration]) {
    setState(() => _hideStuff = false);
    _hideTimer = Timer(duration ?? 1.seconds, () {
      setState(() => _hideStuff = true);
    });
  }
}

class CustomPlayPause extends StatelessWidget {
  const CustomPlayPause({
    super.key,
    required this.controller,
    required this.height,
    required this.onTap,
  });

  final MeeduPlayerController controller;

  final double? height;

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Transform.translate(
      offset: const Offset(0, 0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: height,
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
      ),
    );
  }
}

class PositionWidget extends StatelessWidget {
  const PositionWidget({super.key, required this.controller});

  final MeeduPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return RxBuilder((_) {
      final Duration position = controller.position.value;
      final Duration duration = controller.duration.value;

      return Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: fonts.headlineSmall!.copyWith(color: style.colors.onPrimary),
      );
    });
  }
}

class CustomProgressBar extends StatelessWidget {
  const CustomProgressBar({
    super.key,
    required this.controller,
    required this.onDragStart,
    required this.onDragEnd,
  });

  final MeeduPlayerController controller;

  final dynamic Function()? onDragStart;

  final dynamic Function()? onDragEnd;

  @override
  Widget build(BuildContext context) {
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
}

class MuteButton extends StatelessWidget {
  const MuteButton({
    super.key,
    required this.controller,
    required this.height,
    required this.onTap,
    required this.onEnter,
  });

  final MeeduPlayerController controller;

  final double? height;

  final void Function()? onTap;

  final void Function(PointerEnterEvent)? onEnter;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: onEnter,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRect(
          child: SizedBox(
            height: height,
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

class ExpandButton extends StatelessWidget {
  const ExpandButton({
    super.key,
    required this.height,
    required this.isFullscreen,
    required this.onTap,
  });

  final double? height;

  final bool isFullscreen;

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: Icon(
              isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: style.colors.onPrimary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class HitArea extends StatelessWidget {
  const HitArea({
    super.key,
    required this.controller,
    required this.opacity,
    required this.onPressed,
  });

  final MeeduPlayerController controller;

  final double opacity;

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return RxBuilder((_) {
      final bool isFinished =
          controller.position.value >= controller.duration.value;

      return Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: controller.playerStatus.playing
              ? Container()
              : AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: style.colors.onBackgroundOpacity13,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 32,
                      icon: isFinished
                          ? Icon(Icons.replay, color: style.colors.onPrimary)
                          : AnimatedPlayPause(
                              color: style.colors.onPrimary,
                              playing: controller.playerStatus.playing,
                            ),
                      onPressed: onPressed,
                    ),
                  ),
                ),
        ),
      );
    });
  }
}

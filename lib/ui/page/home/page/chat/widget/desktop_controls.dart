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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/page/chat/widget/bottom_control_bar.dart';

import '/themes.dart';
import '/ui/widget/progress_indicator.dart';
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

  /// [Timer] for hiding user interface on [_initialize].
  Timer? _initTimer;

  /// [Timer] for showing user interface for a while after fullscreen toggle.
  Timer? _showAfterExpandCollapseTimer;

  /// [StreamSubscription] to the [MeeduPlayerController.playerStatus] changes.
  StreamSubscription? _statusSubscription;

  /// Indicator whether the video progress bar is being dragged.
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
    _initTimer?.cancel();
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
            RxBuilder((_) {
              return widget.controller.isBuffering.value
                  ? const Center(child: CustomProgressIndicator())
                  : _buildHitArea();
            }),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BottomControlBar(
                  controller: widget.controller,
                  volumeKey: _volumeKey,
                  barHeight: _barHeight,
                  isOpen: _showBottomBar || _showInterface,
                  isFullscreen: widget.isFullscreen?.value == true,
                  playPause: _playPause,
                  onTap2: _onExpandCollapse,
                  onTap: () {
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
                  onEnter: (_) {
                    if (mounted && _volumeEntry == null) {
                      Offset offset = Offset.zero;
                      final keyContext = _volumeKey.currentContext;
                      if (keyContext != null) {
                        final box = keyContext.findRenderObject() as RenderBox;
                        offset = box.localToGlobal(Offset.zero);
                      }

                      _volumeEntry =
                          OverlayEntry(builder: (_) => _volumeOverlay(offset));
                      Overlay.of(context, rootOverlay: true)
                          .insert(_volumeEntry!);
                      setState(() {});
                    }
                  },
                )
              ],
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
                    _volumeEntry?.remove();
                    _volumeEntry = null;
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

  /// Returns the [Center]ed play/pause circular button.
  Widget _buildHitArea() {
    final style = Theme.of(context).style;

    return RxBuilder((_) {
      final bool isFinished =
          widget.controller.position.value >= widget.controller.duration.value;

      return Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.controller.playerStatus.playing
              ? Container()
              : AnimatedOpacity(
                  opacity:
                      !_dragging && !_hideStuff || _showInterface ? 1.0 : 0.0,
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
                              playing: widget.controller.playerStatus.playing,
                            ),
                      onPressed: _playPause,
                    ),
                  ),
                ),
        ),
      );
    });
  }

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
              if (mounted) {
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
                            child: VideoVolumeBar(
                              widget.controller,
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

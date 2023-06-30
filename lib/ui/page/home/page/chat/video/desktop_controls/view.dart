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

import 'package:chewie/chewie.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:get/get.dart';

import '/ui/widget/progress_indicator.dart';
import 'widget/bottom_control_bar.dart';
import 'widget/hit_area.dart';
import 'widget/volume_overlay.dart';

/// Desktop video controls for a [Chewie] player.
class DesktopControlsView extends StatefulWidget {
  const DesktopControlsView({
    super.key,
    required this.controller,
    this.onClose,
    this.toggleFullscreen,
    this.isFullscreen,
    this.showInterfaceFor,
  });

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// Indicator of whether this video is in fullscreen mode.
  final bool? isFullscreen;

  /// [Duration] to initially show an user interface for.
  final Duration? showInterfaceFor;

  /// Callback, called when a close video action is fired.
  final void Function()? onClose;

  /// Callback, called when a toggle fullscreen action is fired.
  final void Function()? toggleFullscreen;

  @override
  State<StatefulWidget> createState() => _DesktopControlsState();
}

/// State of [DesktopControlsView], used to control a video.
class _DesktopControlsState extends State<DesktopControlsView>
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
              children: [
                BottomControlBar(
                  controller: widget.controller,
                  volumeKey: _volumeKey,
                  barHeight: _barHeight,
                  isOpen: _showBottomBar || _showInterface,
                  isFullscreen: widget.isFullscreen == true,
                  onPlayPause: _playPause,
                  onFullscreen: _onExpandCollapse,
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
                  onEnter: (_) {
                    if (mounted && _volumeEntry == null) {
                      Offset offset = Offset.zero;
                      final keyContext = _volumeKey.currentContext;
                      if (keyContext != null) {
                        final box = keyContext.findRenderObject() as RenderBox;
                        offset = box.localToGlobal(Offset.zero);
                      }

                      _volumeEntry = OverlayEntry(
                        builder: (_) => VolumeOverlay(
                          controller: widget.controller,
                          offset: offset,
                          onExit: (d) {
                            if (mounted) {
                              _volumeEntry?.remove();
                              _volumeEntry = null;
                              setState(() {});
                            }
                          },
                        ),
                      );
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

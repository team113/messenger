// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '/themes.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/widget/progress_indicator.dart';
import 'centered_play_pause.dart';
import 'custom_play_pause.dart';
import 'expand_button.dart';
import 'position.dart';
import 'video_progress_bar.dart';
import 'volume_button.dart';
import 'volume_overlay.dart';

/// Desktop video controls for a [VideoView] player.
class DesktopControls extends StatefulWidget {
  const DesktopControls(
    this.controller, {
    super.key,
    this.onClose,
    this.toggleFullscreen,
    this.isFullscreen,
    this.showInterfaceFor,
    this.size,
    this.barHeight,
  });

  /// [VideoController] controlling the [Video] player functionality.
  final VideoController controller;

  /// Height of the bottom controls bar.
  final double? barHeight;

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

  /// [StreamSubscription] to the [Player.stream.playing] changes.
  StreamSubscription? _playingSubscription;

  /// Indicator whether the video or volume progress bar is being dragged.
  bool _dragging = false;

  @override
  void initState() {
    _playingSubscription = widget.controller.player.stream.playing.listen((
      playing,
    ) {
      if (!playing) {
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
    _playingSubscription?.cancel();
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
            StreamBuilder(
              stream: widget.controller.player.stream.buffering,
              initialData: widget.controller.player.state.buffering,
              builder: (_, buffering) {
                return buffering.data!
                    ? const Center(child: CustomProgressIndicator())
                    : CenteredPlayPause(
                        widget.controller,
                        show:
                            (!_dragging && !_hideStuff || _showInterface) &&
                            !widget.controller.player.state.playing,
                        onPressed: _playPause,
                      );
              },
            ),
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
                    widget.controller,
                    height: widget.barHeight,
                    onTap: _playPause,
                  ),
                  const SizedBox(width: 12),
                  CurrentPosition(widget.controller),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProgressBar(
                      widget.controller,
                      onDragStart: () {
                        setState(() => _dragging = true);
                        _hideTimer?.cancel();
                      },
                      onDragEnd: () {
                        setState(() => _dragging = false);
                        _startHideTimer();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  VolumeButton(
                    widget.controller,
                    key: _volumeKey,
                    height: widget.barHeight,
                    onTap: () {
                      _cancelAndRestartTimer();
                      if (widget.controller.player.state.volume == 0) {
                        widget.controller.player.setVolume(
                          _latestVolume ?? 0.5,
                        );
                      } else {
                        _latestVolume = widget.controller.player.state.volume;
                        widget.controller.player.setVolume(0.0);
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
                          builder: (_) => VolumeOverlay(
                            widget.controller,
                            offset: offset,
                            onExit: (d) {
                              if (mounted && !_dragging) {
                                _volumeEntry?.remove();
                                _volumeEntry = null;
                                setState(() {});
                              }
                            },
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
                          ),
                        );
                        Overlay.of(
                          context,
                          rootOverlay: true,
                        ).insert(_volumeEntry!);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  ExpandButton(
                    height: widget.barHeight,
                    fullscreen: widget.isFullscreen?.value == true,
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
    final isFinished = widget.controller.player.state.completed;

    if (widget.controller.player.state.playing) {
      _cancelAndRestartTimer();
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

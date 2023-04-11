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
import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:chewie/src/animated_play_pause.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:chewie/src/progress_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '/ui/page/home/widget/animated_slider.dart';
import '/ui/widget/progress_indicator.dart';
import 'progress_bar.dart';

/// Desktop video controls for a [Chewie] player.
class DesktopControls extends StatefulWidget {
  const DesktopControls({
    Key? key,
    this.onClose,
    this.toggleFullscreen,
    this.isFullscreen,
    this.showInterfaceFor,
  }) : super(key: key);

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

  /// [VideoPlayerController] controlling the video playback.
  late VideoPlayerController _controller;

  /// [ChewieController] controlling the [Chewie] functionality.
  late ChewieController _chewieController;

  /// [ChewieController], previously assigned to the [_chewieController].
  ChewieController? _oldController;

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

  /// Latest [VideoPlayerValue] value.
  late VideoPlayerValue _latestValue;

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

  /// Indicator whether the video progress bar is being dragged.
  final bool _dragging = false;

  @override
  void initState() {
    Future.delayed(
      Duration.zero,
      () => _startInterfaceTimer(widget.showInterfaceFor),
    );
    super.initState();
  }

  @override
  void dispose() {
    _dispose();
    _volumeEntry?.remove();
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
    final iconColor = Theme.of(context).textTheme.labelLarge!.color;

    if (_latestValue.hasError) {
      return _chewieController.errorBuilder
              ?.call(context, _controller.value.errorDescription!) ??
          const Center(child: Icon(Icons.error, color: Colors.white, size: 42));
    }

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
                child: AspectRatio(
                  aspectRatio: _chewieController.aspectRatio ??
                      _controller.value.aspectRatio,
                  // Single tap inside [AspectRatio] toggles play/pause.
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
            _latestValue.isBuffering
                ? const Center(child: CustomProgressIndicator())
                : _BuildHitArea(
                    latestValue: _latestValue,
                    controller: _controller,
                    dragging: _dragging,
                    hideStuff: _hideStuff,
                    showInterface: _showInterface,
                    playPause: _playPause,
                  ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _BuildBottomBar(
                    showBottomBar: _showBottomBar,
                    showInterface: _showInterface,
                    controller: _controller,
                    playPause: _playPause,
                    barHeight: _barHeight,
                    iconColor: iconColor,
                    latestValue: _latestValue,
                    dragging: _dragging,
                    hideTimer: _hideTimer,
                    startHideTimer: _startHideTimer,
                    chewieController: _chewieController,
                    volumeEntry: _volumeEntry,
                    volumeKey: _volumeKey,
                    cancelAndRestartTimer: _cancelAndRestartTimer,
                    latestVolume: _latestVolume,
                    onExpandCollapse: _onExpandCollapse,
                    isFullscreen: widget.isFullscreen)
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

  /// Initializes this [DesktopControls].
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

  /// Disposes this [DesktopControls].
  void _dispose() {
    _controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
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
    final isFinished = _latestValue.position >= _latestValue.duration;

    if (_controller.value.isPlaying) {
      _cancelAndRestartTimer();
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

  /// Invokes [setState] with a new [_latestValue] if [mounted].
  void _updateState() {
    if (!mounted) return;
    setState(() => _latestValue = _controller.value);

    if (!_controller.value.isPlaying) {
      _startInterfaceTimer(3.seconds);
    }
  }
}

/// Returns the bottom controls bar.
class _BuildBottomBar extends StatelessWidget {
  final bool showBottomBar;
  final bool showInterface;
  final VideoPlayerController controller;
  final void Function()? playPause;
  final double barHeight;
  final Color? iconColor;
  final VideoPlayerValue latestValue;
  final bool dragging;
  final Timer? hideTimer;
  final void Function(Duration? duration)? startHideTimer;
  final ChewieController chewieController;
  final OverlayEntry? volumeEntry;
  final GlobalKey<State<StatefulWidget>> volumeKey;
  final void Function()? cancelAndRestartTimer;
  final double? latestVolume;
  final void Function()? onExpandCollapse;

  /// Reactive indicator of whether this video is in fullscreen mode.
  final RxBool? isFullscreen;

  const _BuildBottomBar({
    Key? key,
    required this.showBottomBar,
    required this.showInterface,
    required this.controller,
    required this.playPause,
    required this.barHeight,
    required this.iconColor,
    required this.latestValue,
    required this.dragging,
    required this.hideTimer,
    required this.startHideTimer,
    required this.chewieController,
    required this.volumeEntry,
    required this.volumeKey,
    required this.cancelAndRestartTimer,
    required this.latestVolume,
    required this.onExpandCollapse,
    required this.isFullscreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.labelLarge!.color;

    return AnimatedSlider(
      duration: const Duration(milliseconds: 300),
      isOpen: showBottomBar || showInterface,
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
                color: const Color(0x66000000),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 7),
                  _BuildPlayPause(
                    controller: controller,
                    playPause: playPause,
                    barHeight: barHeight,
                  ),
                  const SizedBox(width: 12),
                  _BuildPosition(
                    iconColor: iconColor,
                    latestValue: latestValue,
                  ),
                  const SizedBox(width: 12),
                  _BuildProgressBar(
                    controller: controller,
                    dragging: dragging,
                    hideTimer: hideTimer,
                    startHideTimer: startHideTimer,
                    chewieController: chewieController,
                  ),
                  const SizedBox(width: 12),
                  _BuildMuteButton(
                    controller: controller,
                    volumeKey: volumeKey,
                    chewieController: chewieController,
                    cancelAndRestartTimer: cancelAndRestartTimer,
                    latestValue: latestValue,
                    barHeight: barHeight,
                    latestVolume: latestVolume,
                    volumeEntry: volumeEntry,
                  ),
                  const SizedBox(width: 12),
                  _BuildExpandButton(
                    onExpandCollapse: onExpandCollapse,
                    barHeight: barHeight,
                    isFullscreen: isFullscreen,
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
}

/// Returns the play/pause button.
class _BuildPlayPause extends StatelessWidget {
  final VideoPlayerController controller;
  final void Function()? playPause;
  final double barHeight;
  const _BuildPlayPause({
    Key? key,
    required this.controller,
    required this.playPause,
    required this.barHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 0),
      child: GestureDetector(
        onTap: playPause,
        child: Container(
          height: barHeight,
          color: Colors.transparent,
          child: AnimatedPlayPause(
            size: 21,
            playing: controller.value.isPlaying,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Returns the [Text] of the current video position.
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

    return Text(
      '${formatDuration(position)} / ${formatDuration(duration)}',
      style: const TextStyle(fontSize: 14.0, color: Colors.white),
    );
  }
}

class _BuildProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  bool dragging;
  final Timer? hideTimer;
  final void Function(Duration? duration)? startHideTimer;
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
        drawShadow: false,
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

/// Returns the [_volumeEntry] overlay.
class _VolumeOverlay extends StatefulWidget {
  _VolumeOverlay({
    Key? key,
    required this.chewieController,
    required this.offset,
    required this.volumeEntry,
  }) : super(key: key);
  final Offset offset;
  OverlayEntry? volumeEntry;
  final ChewieController chewieController;

  @override
  State<_VolumeOverlay> createState() => _VolumeOverlayState();
}

class _VolumeOverlayState extends State<_VolumeOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: widget.offset.dx - 6,
          bottom: 10,
          child: MouseRegion(
            opaque: false,
            onExit: (d) {
              if (mounted) {
                widget.volumeEntry?.remove();
                widget.volumeEntry = null;
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
                          color: const Color(0x66000000),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            child: VideoVolumeBar(
                              widget.chewieController.videoPlayerController,
                              colors: widget
                                  .chewieController.materialProgressColors!,
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
}

/// Returns the mute/unmute button with a volume overlay above it.
class _BuildMuteButton extends StatefulWidget {
  _BuildMuteButton({
    Key? key,
    required this.controller,
    required this.volumeKey,
    required this.chewieController,
    required this.cancelAndRestartTimer,
    required this.latestValue,
    required this.barHeight,
    required this.latestVolume,
    required this.volumeEntry,
  }) : super(key: key);

  final VideoPlayerController controller;

  OverlayEntry? volumeEntry;

  final GlobalKey<State<StatefulWidget>> volumeKey;

  final ChewieController chewieController;
  final void Function()? cancelAndRestartTimer;
  final VideoPlayerValue latestValue;
  double? latestVolume;
  final double barHeight;

  @override
  State<_BuildMuteButton> createState() => _BuildMuteButtonState();
}

class _BuildMuteButtonState extends State<_BuildMuteButton> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted && widget.volumeEntry == null) {
          Offset offset = Offset.zero;
          final keyContext = widget.volumeKey.currentContext;
          if (keyContext != null) {
            final box = keyContext.findRenderObject() as RenderBox;
            offset = box.localToGlobal(Offset.zero);
          }

          widget.volumeEntry = OverlayEntry(
              builder: (_) => _VolumeOverlay(
                    chewieController: widget.chewieController,
                    offset: offset,
                    volumeEntry: widget.volumeEntry,
                  ));
          Overlay.of(context, rootOverlay: true).insert(widget.volumeEntry!);
          setState(() {});
        }
      },
      child: GestureDetector(
        onTap: () {
          widget.cancelAndRestartTimer;
          if (widget.latestValue.volume == 0) {
            widget.controller.setVolume(widget.latestVolume ?? 0.5);
          } else {
            widget.latestVolume = widget.controller.value.volume;
            widget.controller.setVolume(0.0);
          }
        },
        child: ClipRect(
          child: SizedBox(
            key: widget.volumeKey,
            height: widget.barHeight,
            child: Icon(
              widget.latestValue.volume > 0
                  ? Icons.volume_up
                  : Icons.volume_off,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns the fullscreen toggling button.
class _BuildExpandButton extends StatelessWidget {
  final void Function()? onExpandCollapse;
  final double barHeight;

  /// Reactive indicator of whether this video is in fullscreen mode.
  final RxBool? isFullscreen;
  const _BuildExpandButton({
    Key? key,
    required this.onExpandCollapse,
    required this.barHeight,
    required this.isFullscreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: onExpandCollapse,
        child: SizedBox(
          height: barHeight,
          child: Center(
            child: Icon(
              isFullscreen?.value == true
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: Colors.white,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns the [Center]ed play/pause circular button.
class _BuildHitArea extends StatelessWidget {
  final VideoPlayerValue latestValue;
  final VideoPlayerController controller;
  final bool dragging;
  final bool hideStuff;
  final bool showInterface;
  final void Function()? playPause;
  const _BuildHitArea({
    Key? key,
    required this.latestValue,
    required this.controller,
    required this.dragging,
    required this.hideStuff,
    required this.showInterface,
    required this.playPause,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isFinished = latestValue.position >= latestValue.duration;

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: controller.value.isPlaying
            ? Container()
            : AnimatedOpacity(
                opacity: !dragging && !hideStuff || showInterface ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 32,
                    icon: isFinished
                        ? const Icon(Icons.replay, color: Colors.white)
                        : AnimatedPlayPause(
                            color: Colors.white,
                            playing: controller.value.isPlaying,
                          ),
                    onPressed: playPause,
                  ),
                ),
              ),
      ),
    );
  }
}

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

import '/themes.dart';
import 'progress_bar.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/widget/progress_indicator.dart';

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
  bool _dragging = false;

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
    final Style style = Theme.of(context).extension<Style>()!;

    if (_latestValue.hasError) {
      return _chewieController.errorBuilder
              ?.call(context, _controller.value.errorDescription!) ??
          Center(child: Icon(Icons.error, color: style.onPrimary, size: 42));
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
                : _buildHitArea(),
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

  /// Returns the bottom controls bar.
  Widget _buildBottomBar(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final iconColor = Theme.of(context).textTheme.labelLarge!.color;
    return AnimatedSlider(
      duration: const Duration(milliseconds: 300),
      isOpen: _showBottomBar || _showInterface,
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
                color: style.onBackgroundOpacity60,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 7),
                  _buildPlayPause(_controller),
                  const SizedBox(width: 12),
                  _buildPosition(iconColor),
                  const SizedBox(width: 12),
                  _buildProgressBar(),
                  const SizedBox(width: 12),
                  _buildMuteButton(_controller),
                  const SizedBox(width: 12),
                  _buildExpandButton(),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the fullscreen toggling button.
  Widget _buildExpandButton() {
    final Style style = Theme.of(context).extension<Style>()!;
    return Obx(
      () => GestureDetector(
        onTap: _onExpandCollapse,
        child: SizedBox(
          height: _barHeight,
          child: Center(
            child: Icon(
              widget.isFullscreen?.value == true
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: style.onPrimary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the [Center]ed play/pause circular button.
  Widget _buildHitArea() {
    final bool isFinished = _latestValue.position >= _latestValue.duration;
    final Style style = Theme.of(context).extension<Style>()!;

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _controller.value.isPlaying
            ? Container()
            : AnimatedOpacity(
                opacity:
                    !_dragging && !_hideStuff || _showInterface ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: style.onBackgroundOpacity88,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 32,
                    icon: isFinished
                        ? Icon(Icons.replay, color: style.onPrimary)
                        : AnimatedPlayPause(
                            color: style.onPrimary,
                            playing: _controller.value.isPlaying,
                          ),
                    onPressed: _playPause,
                  ),
                ),
              ),
      ),
    );
  }

  /// Returns the play/pause button.
  Widget _buildPlayPause(VideoPlayerController controller) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Transform.translate(
      offset: const Offset(0, 0),
      child: GestureDetector(
        onTap: _playPause,
        child: Container(
          height: _barHeight,
          color: style.transparent,
          child: AnimatedPlayPause(
            size: 21,
            playing: controller.value.isPlaying,
            color: style.onPrimary,
          ),
        ),
      ),
    );
  }

  /// Returns the mute/unmute button with a volume overlay above it.
  Widget _buildMuteButton(VideoPlayerController controller) {
    final Style style = Theme.of(context).extension<Style>()!;

    return MouseRegion(
      onEnter: (_) {
        if (mounted && _volumeEntry == null) {
          Offset offset = Offset.zero;
          final keyContext = _volumeKey.currentContext;
          if (keyContext != null) {
            final box = keyContext.findRenderObject() as RenderBox;
            offset = box.localToGlobal(Offset.zero);
          }

          _volumeEntry = OverlayEntry(builder: (_) => _volumeOverlay(offset));
          Overlay.of(context, rootOverlay: true).insert(_volumeEntry!);
          setState(() {});
        }
      },
      child: GestureDetector(
        onTap: () {
          _cancelAndRestartTimer();
          if (_latestValue.volume == 0) {
            controller.setVolume(_latestVolume ?? 0.5);
          } else {
            _latestVolume = controller.value.volume;
            controller.setVolume(0.0);
          }
        },
        child: ClipRect(
          child: SizedBox(
            key: _volumeKey,
            height: _barHeight,
            child: Icon(
              _latestValue.volume > 0 ? Icons.volume_up : Icons.volume_off,
              color: style.onPrimary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the [_volumeEntry] overlay.
  Widget _volumeOverlay(Offset offset) {
    final Style style = Theme.of(context).extension<Style>()!;

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
                          color: style.onBackgroundOpacity60,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            child: VideoVolumeBar(
                              _chewieController.videoPlayerController,
                              colors: _chewieController.materialProgressColors!,
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

  /// Returns the [Text] of the current video position.
  Widget _buildPosition(Color? iconColor) {
    final Style style = Theme.of(context).extension<Style>()!;

    final position = _latestValue.position;
    final duration = _latestValue.duration;

    return Text(
      '${formatDuration(position)} / ${formatDuration(duration)}',
      style: TextStyle(fontSize: 14.0, color: style.onPrimary),
    );
  }

  /// Returns the [VideoProgressBar] of the current video progression.
  Widget _buildProgressBar() {
    final Style style = Theme.of(context).extension<Style>()!;

    return Expanded(
      child: VideoProgressBar(
        _controller,
        barHeight: 2,
        handleHeight: 6,
        drawShadow: false,
        onDragStart: () {
          setState(() => _dragging = true);
          _hideTimer?.cancel();
        },
        onDragEnd: () {
          setState(() => _dragging = false);
          _startHideTimer();
        },
        colors: _chewieController.materialProgressColors ??
            ChewieProgressColors(
              playedColor: style.secondary,
              handleColor: style.secondary,
              bufferedColor: style.background.withOpacity(0.5),
              backgroundColor: Theme.of(context).disabledColor.withOpacity(.5),
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

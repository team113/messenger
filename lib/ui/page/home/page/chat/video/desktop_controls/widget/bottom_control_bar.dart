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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:messenger/ui/page/home/page/chat/video/widget/video_progress_bar.dart';

import '/themes.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '../../widget/current_position.dart';
import 'expand_button.dart';
import 'mute_button.dart';
import 'play_pause_button.dart';
import 'volume_overlay.dart';

/// Desktop design of a video bottom controls bar.
class BottomControlBar extends StatefulWidget {
  const BottomControlBar({
    super.key,
    required this.controller,
    this.volumeKey,
    this.barHeight,
    this.onPlayPause,
    this.onMute,
    this.onFullscreen,
    this.onDragStart,
    this.onDragEnd,
    this.isFullscreen = false,
    this.visible = true,
  });

  /// [GlobalKey] of the volume button.
  final GlobalKey? volumeKey;

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// Height of this [BottomControlBar].
  final double? barHeight;

  /// Indicator whether this [BottomControlBar] should be visible or not.
  final bool visible;

  /// Indicator whether the video is in fullscreen mode.
  final bool isFullscreen;

  /// Callback, called when the play pause button is tapped.
  final void Function()? onPlayPause;

  /// Callback, called when the mute button is tapped.
  final void Function()? onMute;

  /// Callback, called when the toggle fullscreen button is tapped.
  final void Function()? onFullscreen;

  /// Callback, called when progress drag started.
  final dynamic Function()? onDragStart;

  /// Callback, called when progress drag ended.
  final dynamic Function()? onDragEnd;

  @override
  State<BottomControlBar> createState() => _BottomControlBarState();
}

class _BottomControlBarState extends State<BottomControlBar> {
  /// [OverlayEntry] of the volume popup bar.
  OverlayEntry? _volumeEntry;

  @override
  void dispose() {
    _volumeEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedSlider(
      duration: const Duration(milliseconds: 300),
      isOpen: widget.visible,
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
                  StyledPlayPauseButton(
                    controller: widget.controller,
                    height: widget.barHeight,
                    onTap: widget.onPlayPause,
                  ),
                  const SizedBox(width: 12),
                  CurrentPosition(controller: widget.controller),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProgressBar(
                      widget.controller,
                      drawShadow: false,
                      onDragStart: widget.onDragStart,
                      onDragEnd: widget.onDragEnd,
                    ),
                  ),
                  const SizedBox(width: 12),
                  MuteButton(
                    key: widget.volumeKey,
                    controller: widget.controller,
                    height: widget.barHeight,
                    onEnter: (_) {
                      if (mounted && _volumeEntry == null) {
                        Offset offset = Offset.zero;
                        final keyContext = widget.volumeKey?.currentContext;
                        if (keyContext != null) {
                          final box =
                              keyContext.findRenderObject() as RenderBox;
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
                    onTap: widget.onMute,
                  ),
                  const SizedBox(width: 12),
                  ExpandButton(
                    isFullscreen: widget.isFullscreen,
                    height: widget.barHeight,
                    onTap: widget.onFullscreen,
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

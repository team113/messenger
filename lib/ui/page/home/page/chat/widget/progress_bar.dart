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

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '/routes.dart';
import '/themes.dart';

/// Draggable video volume bar.
///
/// Use [RotatedBox] to rotate it vertically.
class VideoVolumeBar extends StatefulWidget {
  VideoVolumeBar(
    this.controller, {
    Key? key,
    ChewieProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.barHeight = 2,
    this.handleHeight = 6,
    this.drawShadow = false,
  })  : colors = colors ?? ChewieProgressColors(),
        super(key: key);

  /// [VideoPlayerController] used to control the volume.
  final VideoPlayerController controller;

  /// [ChewieProgressColors] theme of this [VideoVolumeBar].
  final ChewieProgressColors colors;

  /// Callback, called when volume drag started.
  final Function()? onDragStart;

  /// Callback, called when volume drag ended.
  final Function()? onDragEnd;

  /// Callback, called when volume drag updated.
  final Function()? onDragUpdate;

  /// Height of the volume bar.
  final double barHeight;

  /// Radius of the volume handle.
  final double handleHeight;

  /// Indicator whether a shadow should be drawn around this [VideoVolumeBar].
  final bool drawShadow;

  @override
  State<VideoVolumeBar> createState() => _VideoVolumeBarState();
}

/// State of a [VideoVolumeBar] used to redraw on [controller] changes.
class _VideoVolumeBarState extends State<VideoVolumeBar> {
  /// Returns [VideoPlayerController] used to control the volume.
  VideoPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_listener);
  }

  @override
  void deactivate() {
    controller.removeListener(_listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (controller.value.isInitialized) {
          widget.onDragStart?.call();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (controller.value.isInitialized) {
          _seekToRelativePosition(details.globalPosition);
          widget.onDragUpdate?.call();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) => widget.onDragEnd?.call(),
      onTapDown: (TapDownDetails details) {
        if (controller.value.isInitialized) {
          _seekToRelativePosition(details.globalPosition);
        }
      },
      child: LayoutBuilder(builder: (context, constraints) {
        return Center(
          child: Container(
            height: constraints.biggest.height,
            width: constraints.biggest.width,
            color: style.transparent,
            child: CustomPaint(
              painter: _ProgressBarPainter(
                value: controller.value,
                colors: widget.colors,
                barHeight: widget.barHeight,
                handleHeight: widget.handleHeight,
                drawShadow: widget.drawShadow,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Transforms the provided [globalPosition] into relative and sets the
  /// volume.
  void _seekToRelativePosition(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    controller.setVolume(relative);
  }

  /// [controller] listener rebuilding the widget if [mounted].
  void _listener() {
    if (!mounted) return;
    setState(() {});
  }
}

/// [CustomPainter] drawing a video volume progress bar.
class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  });

  /// [VideoPlayerValue], used to get the current volume value.
  VideoPlayerValue value;

  /// [ChewieProgressColors] theme of the progress bar.
  ChewieProgressColors colors;

  /// Height of the progress bar.
  final double barHeight;

  /// Radius of the progress bar handle.
  final double handleHeight;

  /// Indicator whether a shadow should be drawn.
  final bool drawShadow;

  @override
  bool shouldRepaint(CustomPainter painter) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final Style style = Theme.of(router.context!).extension<Style>()!;

    final baseOffset = size.height / 2 - barHeight / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(size.width, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );

    if (!value.isInitialized) {
      return;
    }

    final double playedPart = value.volume * size.width;

    for (final DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, baseOffset),
            Offset(end, baseOffset + barHeight),
          ),
          const Radius.circular(4.0),
        ),
        colors.bufferedPaint,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(playedPart, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.playedPaint,
    );

    if (drawShadow) {
      final shadowPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(playedPart, baseOffset + barHeight / 2),
            radius: handleHeight,
          ),
        );

      canvas.drawShadow(shadowPath, style.onBackground, 0.2, false);
    }

    canvas.drawCircle(
      Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handlePaint,
    );
  }
}

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
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '/themes.dart';

/// Draggable video progress bar.
class ProgressBar extends StatefulWidget {
  ProgressBar(
    this.controller, {
    ChewieProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    Key? key,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  })  : colors = colors ?? ChewieProgressColors(),
        super(key: key);

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  /// [ChewieProgressColors] theme of this [ProgressBar].
  final ChewieProgressColors colors;

  /// Callback, called when progress drag started.
  final Function()? onDragStart;

  /// Callback, called when progress drag ended.
  final Function()? onDragEnd;

  /// Callback, called when progress drag updated.
  final Function()? onDragUpdate;

  /// Height of the progress bar.
  final double barHeight;

  /// Radius of the progress handle.
  final double handleHeight;

  /// Indicator whether a shadow should be drawn around this [ProgressBar].
  final bool drawShadow;

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

/// State of a [ProgressBar] handles progress changes.
class _ProgressBarState extends State<ProgressBar> {
  /// Indicator whether video was playing when `dragStart` event triggered.
  bool _controllerWasPlaying = false;

  /// [Offset] to seek to on `dragEnd` event.
  Offset? _latestDraggableOffset;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final child = Center(
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: style.colors.transparent,
        child: RxBuilder((_) {
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CustomPaint(
              painter: _ProgressBarPainter(
                duration: widget.controller.duration.value,
                position: _latestDraggableOffset != null
                    ? _relativePosition(_latestDraggableOffset!)
                    : widget.controller.position.value,
                buffered: widget.controller.buffered.value,
                colors: widget.colors,
                barHeight: widget.barHeight,
                handleHeight: widget.handleHeight,
                drawShadow: widget.drawShadow,
              ),
            ),
          );
        }),
      ),
    );

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (!widget.controller.dataStatus.loaded) {
          return;
        }
        _controllerWasPlaying = widget.controller.playerStatus.playing;
        if (_controllerWasPlaying) {
          widget.controller.pause();
        }

        widget.onDragStart?.call();
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!widget.controller.dataStatus.loaded) {
          return;
        }
        _latestDraggableOffset = details.globalPosition;
        setState(() {});

        widget.onDragUpdate?.call();
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_controllerWasPlaying) {
          widget.controller.play();
        }

        if (_latestDraggableOffset != null) {
          widget.controller.seekTo(_relativePosition(_latestDraggableOffset!));
          _latestDraggableOffset = null;
        }

        widget.onDragEnd?.call();
      },
      onTapDown: (TapDownDetails details) {
        if (!widget.controller.dataStatus.loaded) {
          return;
        }
        widget.controller.seekTo(_relativePosition(details.globalPosition));
      },
      child: child,
    );
  }

  /// Transforms the provided [globalPosition] into relative [Duration].
  Duration _relativePosition(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    return widget.controller.duration.value * relative;
  }
}

/// [CustomPainter] drawing a video progress bar.
class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.duration,
    required this.position,
    required this.buffered,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  });

  /// [Duration] of the progress bar.
  Duration duration;

  /// [Duration] of the current position.
  Duration position;

  /// [List] of buffered [DurationRange]s.
  List<DurationRange> buffered;

  /// [ChewieProgressColors] theme of this [_ProgressBarPainter].
  ChewieProgressColors colors;

  /// Height of the progress bar.
  final double barHeight;

  /// Radius of the progress bar handle.
  final double handleHeight;

  /// Indicator whether a shadow should be drawn.
  final bool drawShadow;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
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

    final double playedPartPercent =
        position.inMilliseconds / duration.inMilliseconds;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (final DurationRange range in buffered) {
      final double start = range.startFraction(duration) * size.width;
      final double end = range.endFraction(duration) * size.width;
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
      final Path shadowPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(playedPart, baseOffset + barHeight / 2),
            radius: handleHeight,
          ),
        );

      canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    }

    canvas.drawCircle(
      Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handlePaint,
    );
  }
}

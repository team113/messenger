// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/material.dart';

import '/themes.dart';
import 'video_volume_bar.dart';

/// Draggable video progress bar.
class ProgressBar extends StatefulWidget {
  const ProgressBar({
    this.buffer = Duration.zero,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.isPlaying = false,
    this.onPause,
    this.onPlay,
    this.seekTo,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    super.key,
    this.barHeight = 2,
    this.handleHeight = 6,
    this.drawShadow = true,
  });

  /// [Duration] that should be displayed as a buffered (greyed out) section.
  final Duration buffer;

  /// Whole total [Duration] to calculate [buffer] and [position] relative to.
  final Duration duration;

  /// Current relative position to display.
  final Duration position;

  /// Indicator whether this [ProgressBar] is considered playing.
  final bool isPlaying;

  /// Callback, called when pause should happen.
  final void Function()? onPause;

  /// Callback, called when play should happen.
  final void Function()? onPlay;

  /// Callback, called when seeking should happen.
  final Future<void> Function(Duration)? seekTo;

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

  /// Current position of this [ProgressBar].
  late Duration _position;

  @override
  void initState() {
    _position = widget.position;
    super.initState();
  }

  @override
  void didUpdateWidget(ProgressBar oldWidget) {
    _position = widget.position;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final child = Center(
      child: Container(
        color: style.colors.transparent,
        width: double.infinity,
        height: 24,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: CustomPaint(
            painter: _ProgressBarPainter(
              duration: widget.duration,
              position: _position,
              buffered: widget.buffer,
              colors: ProgressBarColors(
                played: style.colors.primary,
                handle: style.colors.primary,
                buffered: style.colors.background.withValues(alpha: 0.5),
                background: style.colors.secondary.withValues(alpha: 0.5),
              ),
              barHeight: widget.barHeight,
              handleHeight: widget.handleHeight,
              drawShadow: widget.drawShadow,
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        _controllerWasPlaying = widget.isPlaying;
        if (_controllerWasPlaying) {
          widget.onPause?.call();
        }

        widget.onDragStart?.call();
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        _position = _relativePosition(details.globalPosition);
        setState(() {});

        widget.onDragUpdate?.call();
      },
      onHorizontalDragEnd: (DragEndDetails details) async {
        await widget.seekTo?.call(_position);

        if (_controllerWasPlaying) {
          widget.onPlay?.call();
        }

        widget.onDragEnd?.call();
      },
      onTapDown: (TapDownDetails details) {
        _position = _relativePosition(details.globalPosition);
        setState(() {});

        widget.seekTo?.call(_position);
      },
      child: child,
    );
  }

  /// Transforms the provided [globalPosition] into relative [Duration].
  Duration _relativePosition(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final Offset position = box.globalToLocal(globalPosition);
    if (position.dx > 0) {
      final double relative = position.dx / box.size.width;
      return widget.duration * relative;
    } else {
      return Duration.zero;
    }
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
  Duration buffered;

  /// [ProgressBarColors] theme of this [_ProgressBarPainter].
  ProgressBarColors colors;

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
      colors.background,
    );

    final double playedPartPercent = duration == Duration.zero
        ? 0
        : position.inMilliseconds / duration.inMilliseconds;
    final double playedPart = playedPartPercent > 1
        ? size.width
        : playedPartPercent * size.width;

    final double end = duration == Duration.zero
        ? 0
        : (buffered.inMilliseconds / duration.inMilliseconds) * size.width;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, baseOffset),
          Offset(end, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.buffered,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(playedPart, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.played,
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
      colors.handle,
    );
  }
}

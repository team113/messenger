// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:media_kit_video/media_kit_video.dart';

import '/themes.dart';
import 'video_volume_bar.dart';

/// Draggable video progress bar.
class ProgressBar extends StatefulWidget {
  const ProgressBar(
    this.controller, {
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    super.key,
    this.barHeight = 2,
    this.handleHeight = 6,
    this.drawShadow = true,
  });

  /// [VideoController] controlling the [Video] player functionality.
  final VideoController controller;

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

  /// [StreamSubscription] for the [VideoController] position changes updating
  /// the [_position].
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    _position = widget.controller.player.state.position;
    _positionSubscription =
        widget.controller.player.stream.position.listen((e) => _position = e);

    super.initState();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final child = Center(
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: style.colors.transparent,
        child: StreamBuilder(
          stream: widget.controller.player.stream.buffer,
          initialData: widget.controller.player.state.buffer,
          builder: (_, buffer) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: CustomPaint(
                painter: _ProgressBarPainter(
                  duration: widget.controller.player.state.duration,
                  position: _position,
                  buffered: buffer.data!,
                  colors: ProgressBarColors(
                    played: style.colors.primary,
                    handle: style.colors.primary,
                    buffered: style.colors.background.withOpacity(0.5),
                    background: style.colors.secondary.withOpacity(0.5),
                  ),
                  barHeight: widget.barHeight,
                  handleHeight: widget.handleHeight,
                  drawShadow: widget.drawShadow,
                ),
              ),
            );
          },
        ),
      ),
    );

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        _controllerWasPlaying = widget.controller.player.state.playing;
        if (_controllerWasPlaying) {
          widget.controller.player.pause();
        }

        widget.onDragStart?.call();
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        _position = _relativePosition(details.globalPosition);
        setState(() {});

        widget.onDragUpdate?.call();
      },
      onHorizontalDragEnd: (DragEndDetails details) async {
        await widget.controller.player.seek(_position);

        if (_controllerWasPlaying) {
          widget.controller.player.play();
        }

        widget.onDragEnd?.call();
      },
      onTapDown: (TapDownDetails details) {
        _position = _relativePosition(details.globalPosition);
        setState(() {});

        widget.controller.player.seek(_position);
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
      return widget.controller.player.state.duration * relative;
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

    final double playedPartPercent =
        position.inMilliseconds / duration.inMilliseconds;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;

    final double end =
        (buffered.inMilliseconds / duration.inMilliseconds) * size.width;
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

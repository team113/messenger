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

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '/routes.dart';
import '/themes.dart';

/// Draggable video volume bar.
///
/// Use [RotatedBox] to rotate it vertically.
class VideoVolumeBar extends StatelessWidget {
  VideoVolumeBar(
    this.controller, {
    super.key,
    ProgressBarColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.barHeight = 2,
    this.handleHeight = 6,
    this.drawShadow = false,
  }) : colors = colors ?? ProgressBarColors();

  /// [VideoController] used to control the volume.
  final VideoController controller;

  /// [ProgressBarColors] theme of this [VideoVolumeBar].
  final ProgressBarColors colors;

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
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        onDragStart?.call();
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        _seekToRelativePosition(details.globalPosition, context);
        onDragUpdate?.call();
      },
      onHorizontalDragEnd: (DragEndDetails details) => onDragEnd?.call(),
      onTapDown: (TapDownDetails details) {
        _seekToRelativePosition(details.globalPosition, context);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              height: constraints.biggest.height,
              width: constraints.biggest.width,
              color: style.colors.transparent,
              child: StreamBuilder(
                stream: controller.player.stream.volume,
                initialData: controller.player.state.volume,
                builder: (_, volume) {
                  return CustomPaint(
                    painter: ProgressBarPainter(
                      volume: volume.data! / 100,
                      colors: colors,
                      barHeight: barHeight,
                      handleHeight: handleHeight,
                      drawShadow: drawShadow,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Transforms the provided [globalPosition] into relative and sets the
  /// volume.
  void _seekToRelativePosition(Offset globalPosition, BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    controller.player.setVolume(relative.clamp(0, 1) * 100);
  }
}

/// [CustomPainter] drawing a video volume progress bar.
class ProgressBarPainter extends CustomPainter {
  ProgressBarPainter({
    required this.volume,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  });

  /// Current volume value.
  double volume;

  /// [ProgressBarColors] theme of the progress bar.
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
      colors.background,
    );

    final double playedPart = volume * size.width;

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
      final shadowPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(playedPart, baseOffset + barHeight / 2),
            radius: handleHeight,
          ),
        );

      canvas.drawShadow(shadowPath, style.colors.onBackground, 0.2, false);
    }

    canvas.drawCircle(
      Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handle,
    );
  }
}

/// [Color]s to paint [ProgressBarPainter] with.
class ProgressBarColors {
  ProgressBarColors({
    Color played = const Color.fromRGBO(255, 0, 0, 0.7),
    Color buffered = const Color.fromRGBO(30, 30, 200, 0.2),
    Color handle = const Color.fromRGBO(200, 200, 200, 1.0),
    Color background = const Color.fromRGBO(200, 200, 200, 0.5),
  }) : played = Paint()..color = played,
       buffered = Paint()..color = buffered,
       handle = Paint()..color = handle,
       background = Paint()..color = background;

  /// [Paint] to paint played part of [ProgressBarPainter] with.
  final Paint played;

  /// [Paint] to paint buffered part of [ProgressBarPainter] with.
  final Paint buffered;

  /// [Paint] to paint handle of [ProgressBarPainter] with.
  final Paint handle;

  /// [Paint] to paint background of [ProgressBarPainter] with.
  final Paint background;
}

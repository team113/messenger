import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:video_player/video_player.dart';

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

  final MeeduPlayerController controller;
  final ChewieProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  // ignore: library_private_types_in_public_api
  _ProgressBarState createState() {
    return _ProgressBarState();
  }
}

class _ProgressBarState extends State<ProgressBar> {
  void listener() {
    if (!mounted) return;
    setState(() {});
  }

  bool _controllerWasPlaying = false;

  Offset? _latestDraggableOffset;

  MeeduPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    //controller.addListener(listener);
  }

  @override
  void deactivate() {
    //controller.removeListener(listener);
    super.deactivate();
  }

  void _seekToRelativePosition(Offset globalPosition) {
    controller.seekTo(context.calcRelativePosition(
      controller.duration.value,
      globalPosition,
    ));
  }

  @override
  Widget build(BuildContext context) {
    //final MeeduPlayerController chewieController = MeeduPlayerController.of(context);
    final child = Center(
      child: StaticProgressBar(
        value: controller,
        colors: widget.colors,
        barHeight: widget.barHeight,
        handleHeight: widget.handleHeight,
        drawShadow: widget.drawShadow,
      ),
    );

    return GestureDetector(
            onHorizontalDragStart: (DragStartDetails details) {
              if (!controller.dataStatus.loaded) {
                return;
              }
              _controllerWasPlaying = controller.playerStatus.playing;
              if (_controllerWasPlaying) {
                controller.pause();
              }

              widget.onDragStart?.call();
            },
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              if (!controller.dataStatus.loaded) {
                return;
              }
              _latestDraggableOffset = details.globalPosition;
              listener();

              widget.onDragUpdate?.call();
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              if (_controllerWasPlaying) {
                controller.play();
              }

              if (_latestDraggableOffset != null) {
                _seekToRelativePosition(_latestDraggableOffset!);
                _latestDraggableOffset = null;
              }

              widget.onDragEnd?.call();
            },
            onTapDown: (TapDownDetails details) {
              if (!controller.dataStatus.loaded) {
                return;
              }
              _seekToRelativePosition(details.globalPosition);
            },
            child: child,
          );
  }
}

class StaticProgressBar extends StatelessWidget {
  const StaticProgressBar({
    Key? key,
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    this.latestDraggableOffset,
  }) : super(key: key);

  final Offset? latestDraggableOffset;
  final MeeduPlayerController value;
  final ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child: CustomPaint(
        painter: _ProgressBarPainter(
          value: value,
          draggableValue: context.calcRelativePosition(
            value.duration.value,
            latestDraggableOffset,
          ),
          colors: colors,
          barHeight: barHeight,
          handleHeight: handleHeight,
          drawShadow: drawShadow,
        ),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    required this.draggableValue,
  });

  MeeduPlayerController value;
  ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;
  final Duration draggableValue;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

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
    if (!value.dataStatus.loaded) {
      return;
    }
    final double playedPartPercent = (draggableValue != Duration.zero
            ? draggableValue.inMilliseconds
            : value.position.value.inMilliseconds) /
        value.duration.value.inMilliseconds;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (final DurationRange range in value.buffered.value) {
      final double start = range.startFraction(value.duration.value) * size.width;
      final double end = range.endFraction(value.duration.value) * size.width;
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

extension RelativePositionExtensions on BuildContext {
  Duration calcRelativePosition(
    Duration videoDuration,
    Offset? globalPosition,
  ) {
    if (globalPosition == null) return Duration.zero;
    final box = findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    final Duration position = videoDuration * relative;
    return position;
  }
}

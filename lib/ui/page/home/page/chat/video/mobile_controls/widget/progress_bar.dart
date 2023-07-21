import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '../../widget/video_progress_bar.dart';
import '/themes.dart';

class CustomProgressBar extends StatelessWidget {
  const CustomProgressBar({
    super.key,
    required this.controller,
    required this.onDragStart,
    required this.onDragEnd,
  });

  final MeeduPlayerController controller;

  final dynamic Function()? onDragStart;

  final dynamic Function()? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Expanded(
      child: ProgressBar(
        controller,
        barHeight: 2,
        handleHeight: 6,
        drawShadow: true,
        onDragStart: onDragStart,
        onDragEnd: onDragEnd,
        colors: ChewieProgressColors(
          playedColor: style.colors.primary,
          handleColor: style.colors.primary,
          bufferedColor: style.colors.background.withOpacity(0.5),
          backgroundColor: style.colors.secondary.withOpacity(0.5),
        ),
      ),
    );
  }
}

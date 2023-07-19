// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:chewie/src/animated_play_pause.dart';

import '/themes.dart';

class HitArea extends StatelessWidget {
  const HitArea({
    super.key,
    required this.height,
    required this.controller,
    required this.onTap,
  });

  final MeeduPlayerController controller;

  final double height;

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          color: style.colors.transparent,
          child: RxBuilder((_) {
            return AnimatedPlayPause(
              size: 21,
              playing: controller.playerStatus.playing,
              color: style.colors.onPrimary,
            );
          }),
        ),
      ),
    );
  }
}

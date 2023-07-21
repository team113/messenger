// ignore_for_file: implementation_imports

import 'package:chewie/src/animated_play_pause.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '/themes.dart';

class HitArea extends StatelessWidget {
  const HitArea({
    super.key,
    required this.controller,
    required this.opacity,
    required this.onPressed,
  });

  final MeeduPlayerController controller;

  final double opacity;

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return RxBuilder((_) {
      final bool isFinished =
          controller.position.value >= controller.duration.value;

      return Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: controller.playerStatus.playing
              ? Container()
              : AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: style.colors.onBackgroundOpacity13,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 32,
                      icon: isFinished
                          ? Icon(Icons.replay, color: style.colors.onPrimary)
                          : AnimatedPlayPause(
                              color: style.colors.onPrimary,
                              playing: controller.playerStatus.playing,
                            ),
                      onPressed: onPressed,
                    ),
                  ),
                ),
        ),
      );
    });
  }
}

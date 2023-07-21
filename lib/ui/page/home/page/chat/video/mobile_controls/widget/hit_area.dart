// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:chewie/src/center_play_button.dart';
import 'package:messenger/themes.dart';

class HitArea extends StatelessWidget {
  const HitArea({
    super.key,
    required this.controller,
    required this.show,
    required this.onPressed,
  });

  final MeeduPlayerController controller;

  final bool show;

  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return RxBuilder((_) {
      final bool isFinished =
          controller.position.value >= controller.duration.value;

      return CenterPlayButton(
        backgroundColor: style.colors.onBackgroundOpacity13,
        iconColor: style.colors.onPrimary,
        isFinished: isFinished,
        isPlaying: controller.playerStatus.playing,
        show: show,
        onPressed: onPressed,
      );
    });
  }
}

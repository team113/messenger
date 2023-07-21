// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:chewie/src/helpers/utils.dart';

import '/themes.dart';

class PositionWidget extends StatelessWidget {
  const PositionWidget({super.key, required this.controller});

  final MeeduPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return RxBuilder((_) {
      final Duration position = controller.position.value;
      final Duration duration = controller.duration.value;

      return Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: fonts.headlineSmall!.copyWith(color: style.colors.onPrimary),
      );
    });
  }
}

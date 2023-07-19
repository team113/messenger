import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:messenger/themes.dart';
import 'package:chewie/src/helpers/utils.dart';

class PositionWidget extends StatelessWidget {
  const PositionWidget({super.key, required this.controller});

  final MeeduPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return RxBuilder((_) {
      final position = controller.position.value;
      final duration = controller.duration.value;

      return Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: fonts.headlineSmall!.copyWith(color: style.colors.onPrimary),
      );
    });
  }
}

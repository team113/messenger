// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '/themes.dart';

class PositionWidget extends StatelessWidget {
  const PositionWidget({super.key, required this.controller});

  final MeeduPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return RxBuilder((_) {
      final position = controller.position.value;
      final duration = controller.duration.value;

      return RichText(
        text: TextSpan(
          text: '${formatDuration(position)} ',
          children: <InlineSpan>[
            TextSpan(
              text: '/ ${formatDuration(duration)}',
              style: fonts.labelMedium!.copyWith(
                color: style.colors.onPrimaryOpacity50,
              ),
            )
          ],
          style: fonts.labelMedium!.copyWith(color: style.colors.onPrimary),
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '/themes.dart';

class MuteButton extends StatelessWidget {
  const MuteButton({
    super.key,
    required this.controller,
    required this.height,
    required this.opacity,
    required this.onTap,
  });

  final MeeduPlayerController controller;

  final double? height;

  final double opacity;

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: height,
          margin: const EdgeInsets.only(right: 12.0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: RxBuilder((_) {
              return Icon(
                controller.volume.value > 0
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: style.colors.onPrimary,
                size: 18,
              );
            }),
          ),
        ),
      ),
    );
  }
}

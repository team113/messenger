import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '/themes.dart';

class MuteButton extends StatelessWidget {
  const MuteButton({
    super.key,
    required this.controller,
    required this.height,
    required this.onTap,
    required this.onEnter,
  });

  final MeeduPlayerController controller;

  final double? height;

  final void Function()? onTap;

  final void Function(PointerEnterEvent)? onEnter;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: onEnter,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRect(
          child: SizedBox(
            height: height,
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

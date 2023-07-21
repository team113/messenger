import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '../../widget/volume_bar.dart';
import '/themes.dart';

class VolumeOverlay extends StatelessWidget {
  const VolumeOverlay({
    super.key,
    required this.controller,
    required this.offset,
    required this.onExit,
    required this.onDragStart,
    required this.onDragEnd,
  });

  final MeeduPlayerController controller;

  final Offset offset;

  final void Function(PointerExitEvent)? onExit;

  final dynamic Function()? onDragStart;

  final dynamic Function()? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Stack(
      children: [
        Positioned(
          left: offset.dx - 6,
          bottom: 10,
          child: MouseRegion(
            opaque: false,
            onExit: onExit,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: 15,
                        height: 80,
                        decoration: BoxDecoration(
                          color: style.colors.onBackgroundOpacity40,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: VideoVolumeBar(
                                controller,
                                onDragStart: onDragStart,
                                onDragEnd: onDragEnd,
                                colors: ChewieProgressColors(
                                  playedColor: style.colors.primary,
                                  handleColor: style.colors.primary,
                                  bufferedColor:
                                      style.colors.background.withOpacity(0.5),
                                  backgroundColor:
                                      style.colors.secondary.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 27),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

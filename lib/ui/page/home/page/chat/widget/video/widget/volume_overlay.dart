// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'video_volume_bar.dart';
import '/themes.dart';

/// Volume overlay controlling the volume of the provided [controller].
class VolumeOverlay extends StatelessWidget {
  const VolumeOverlay(
    this.controller, {
    super.key,
    this.onExit,
    this.onDragStart,
    this.onDragEnd,
    this.offset = Offset.zero,
  });

  /// [VideoController] controlling the [Video] player functionality.
  final VideoController controller;

  /// Offset of this [VolumeOverlay] from the bottom right corner.
  final Offset offset;

  /// Callback, called when a mouse pointer has exited this [VolumeOverlay].
  final void Function(PointerExitEvent)? onExit;

  /// Callback, called when volume drag started.
  final dynamic Function()? onDragStart;

  /// Callback, called when volume drag ended.
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
                                colors: ProgressBarColors(
                                  played: style.colors.primary,
                                  handle: style.colors.primary,
                                  buffered: style.colors.background
                                      .withValues(alpha: 0.5),
                                  background: style.colors.secondary
                                      .withValues(alpha: 0.5),
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

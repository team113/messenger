// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/material.dart';

/// Widget animating implicitly between a play and a pause icon.
class AnimatedPlayPause extends StatefulWidget {
  const AnimatedPlayPause(this.playing, {super.key, this.size, this.color});

  /// Indicator whether to display a playing icon, or pause otherwise.
  final bool playing;

  /// Size of this [AnimatedPlayPause].
  final double? size;

  /// Color of this [AnimatedPlayPause].
  final Color? color;

  @override
  State<StatefulWidget> createState() => _AnimatedPlayPauseState();
}

/// State of an [AnimatedPlayPause] maintaining the [_controller].
class _AnimatedPlayPauseState extends State<AnimatedPlayPause>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    value: widget.playing ? 1 : 0,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void didUpdateWidget(AnimatedPlayPause oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing != oldWidget.playing) {
      if (widget.playing) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedIcon(
        color: widget.color,
        size: widget.size,
        icon: AnimatedIcons.play_pause,
        progress: _controller,
      ),
    );
  }
}

// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'dart:math';

import 'package:flutter/material.dart';

/// Animated over the provided [period] circles representing an ongoing typing.
class AnimatedTyping extends StatefulWidget {
  const AnimatedTyping({
    Key? key,
    this.period = const Duration(seconds: 1),
  }) : super(key: key);

  /// [Duration] over which the circles are animated.
  final Duration period;

  @override
  State<AnimatedTyping> createState() => _AnimatedTypingState();
}

/// State of an [AnimatedTyping] maintaining the [_controller].
class _AnimatedTypingState extends State<AnimatedTyping>
    with SingleTickerProviderStateMixin {
  /// [AnimationController] animating the circles.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..repeat(period: widget.period);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final Color begin = Theme.of(context).colorScheme.secondary;
        const Color end = Color(0xFFB6DCFF);

        const double size = 4;
        const double spacing = 1.6;

        final Color? color1 = ColorTween(begin: begin, end: end).lerp(
            sin(pi * const Interval(0, 0.3).transform(_controller.value)));
        final Color? color2 = ColorTween(begin: begin, end: end).lerp(
            sin(pi * const Interval(0.3, 0.6).transform(_controller.value)));
        final Color? color3 = ColorTween(begin: begin, end: end).lerp(
            sin(pi * const Interval(0.6, 1).transform(_controller.value)));

        return Row(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color1),
            ),
            const SizedBox(width: spacing),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color2),
            ),
            const SizedBox(width: spacing),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color3),
            ),
            const SizedBox(width: spacing),
          ],
        );
      },
    );
  }
}

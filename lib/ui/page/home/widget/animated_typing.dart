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

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// [Text] represented three dots that change their count over [duration].
class AnimatedTyping extends StatefulWidget {
  const AnimatedTyping({
    Key? key,
    this.duration = const Duration(milliseconds: 250),
    this.color = Colors.white,
  }) : super(key: key);

  /// [Duration] over which the count of dots is changed.
  final Duration duration;

  /// Color of the dots.
  final Color color;

  @override
  State<AnimatedTyping> createState() => _AnimatedTypingState();
}

/// State of an [AnimatedTyping] used to animate the dots.
class _AnimatedTypingState extends State<AnimatedTyping>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this)
      ..repeat(period: const Duration(seconds: 1));
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
      builder: (context, child) {
        Color begin = Theme.of(context).colorScheme.secondary;
        const Color end = Color(0xFFB6DCFF);

        const double size = 4;
        const double spacing = 1.6;

        Color? color1 = ColorTween(begin: begin, end: end).lerp(
            sin(pi * const Interval(0.0, 0.3).transform(_controller.value)));
        Color? color2 = ColorTween(begin: begin, end: end).lerp(
            sin(pi * const Interval(0.3, 0.6).transform(_controller.value)));
        Color? color3 = ColorTween(begin: begin, end: end).lerp(
            sin(pi * const Interval(0.6, 1.0).transform(_controller.value)));

        return Row(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color1,
              ),
            ),
            const SizedBox(width: spacing),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color2,
              ),
            ),
            const SizedBox(width: spacing),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color3,
              ),
            ),
            const SizedBox(width: spacing),
          ],
        );
      },
    );
  }
}

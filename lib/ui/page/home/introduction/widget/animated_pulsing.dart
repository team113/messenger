// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

/// Animated [Opacity] over the provided [child] in a pulse-like animation.
class AnimatedPulsing extends StatefulWidget {
  const AnimatedPulsing({
    super.key,
    this.duration = const Duration(milliseconds: 1000),
    this.child,
  });

  /// [Duration] of pulse-like animation.
  final Duration duration;

  /// [Widget] to animate.
  final Widget? child;

  @override
  State<AnimatedPulsing> createState() => _AnimatedPulsingState();
}

/// State of a [AnimatedPulsing] used for [AnimationController] maintaining.
class _AnimatedPulsingState extends State<AnimatedPulsing>
    with SingleTickerProviderStateMixin {
  /// [AnimationController] animating the pulse animation.
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    super.initState();
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
        return Opacity(
          opacity: Tween(
            begin: 0.3,
            end: 1.0,
          ).evaluate(CurvedAnimation(parent: _controller, curve: Curves.ease)),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

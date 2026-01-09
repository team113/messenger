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

/// Widget rotating the [child] when pressed.
class AnimatedRotatedButton extends StatefulWidget {
  const AnimatedRotatedButton({super.key, required this.child});

  /// [Widget] to rotate.
  final Widget child;

  @override
  State<AnimatedRotatedButton> createState() => _AnimatedRotatedButtonState();
}

/// State of an [AnimatedRotatedButton] maintaining the animation.
class _AnimatedRotatedButtonState extends State<AnimatedRotatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _controller.forward(from: 0),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return IgnorePointer(
            ignoring: _controller.isAnimating,
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 2.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.ease),
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

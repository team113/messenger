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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'widget_button.dart';

/// [WidgetButton] animating its size on hover and clicks.
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.child,
    this.decorator = AnimatedButton._defaultDecorator,
    this.onPressed,
    this.onLongPress,
    this.enabled = true,
  });

  /// Multiplier to scale the [child] on hover.
  static const double scale = 1.05;

  /// Widget to animate.
  final Widget child;

  /// Callback, applying non-animated decorations to the [child].
  final Widget Function(Widget child) decorator;

  /// Callback, called when the [child] is pressed.
  final void Function()? onPressed;

  /// Callback, called when the [child] is long-pressed.
  final void Function()? onLongPress;

  /// Indicator whether the animation is enabled.
  final bool enabled;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();

  /// Returns the [child].
  ///
  /// Intended to be used as a default of the [decorator].
  static Widget _defaultDecorator(Widget child) => child;
}

/// State of the [AnimatedButton] maintaining the animation.
class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  /// [AnimationController] controlling the animation.
  late AnimationController _controller;

  /// Indicator whether this [AnimatedButton] is hovered.
  bool _hovered = false;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 300),
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
    if (!widget.enabled) {
      return widget.decorator(widget.child);
    }

    return MouseRegion(
      opaque: false,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (event.buttons == kPrimaryMouseButton) {
            _controller.reset();
            _controller.forward();
          }
        },
        child: WidgetButton(
          onPressed: widget.onPressed,
          onLongPress: widget.onLongPress,
          child: widget.decorator(
            AnimatedScale(
              duration: const Duration(milliseconds: 100),
              scale: _hovered ? AnimatedButton.scale : 1,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Transform.scale(
                    scale:
                        1.0 -
                        Tween<double>(begin: 0.0, end: 0.2)
                            .animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(
                                  0.0,
                                  1.0,
                                  curve: Curves.ease,
                                ),
                              ),
                            )
                            .value +
                        Tween<double>(begin: 0.0, end: 0.2)
                            .animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(
                                  0.5,
                                  1.0,
                                  curve: Curves.ease,
                                ),
                              ),
                            )
                            .value,
                    child: child,
                  );
                },
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

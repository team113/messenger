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

import 'package:flutter/material.dart';

/// Widget doing a slide transition of its child every time [isOpen] changes.
class AnimatedSlider extends StatefulWidget {
  const AnimatedSlider({
    Key? key,
    this.child,
    required this.duration,
    this.reverseDuration,
    this.isOpen = true,
    this.curve = Curves.easeOut,
    this.reverseCurve = Curves.easeOut,
    this.beginOffset = const Offset(0.0, 1.55),
    this.endOffset = const Offset(0.0, 0.0),
    this.translate = true,
    this.animationStream,
  }) : super(key: key);

  /// Widget to animate on [isOpen] changes.
  final Widget? child;

  /// Duration of the transition.
  final Duration duration;

  /// Duration of the reverse transition.
  final Duration? reverseDuration;

  /// Indicator whether the [child] should be visible or not.
  final bool isOpen;

  /// Curve to use in the forward direction.
  final Curve curve;

  /// Curve to use in the reverse direction.
  final Curve reverseCurve;

  /// Offset of the [child] when [isOpen] is `false`.
  final Offset beginOffset;

  /// Offset of the [child] when [isOpen] is `true`.
  final Offset endOffset;

  /// Indicator whether the [Transform.translate] should be used instead of the
  /// [SlideTransition] or not.
  final bool translate;

  /// [StreamController] listening changes of animation.
  final StreamController? animationStream;

  @override
  State<AnimatedSlider> createState() => _AnimatedSliderState();
}

/// State of an [AnimatedSlider] used to keep its [animation].
class _AnimatedSliderState extends State<AnimatedSlider>
    with TickerProviderStateMixin {
  /// Controller of the sliding transition animation.
  late final AnimationController animation;

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      value: widget.isOpen ? 1 : 0,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
    );
    if (widget.animationStream != null) {
      animation.addListener(_animationListener);
    }
  }

  @override
  void dispose() {
    animation.dispose();if
    (widget.animationStream != null) {
      animation.removeListener(_animationListener);
    }
    super.dispose();
  }

  /// Listens changes of animation.
  void _animationListener() {
    widget.animationStream?.add(null);
  }

  @override
  void didUpdateWidget(covariant AnimatedSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      if (widget.isOpen) {
        animation.forward(from: animation.value);
      } else {
        animation.reverse(from: animation.value);
      }
    }
    if (widget.animationStream != null) {
      _animationListener();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          if (widget.translate) {
            return Transform.translate(
              offset: Tween(
                begin: widget.beginOffset,
                end: widget.endOffset,
              ).evaluate(
                CurvedAnimation(
                  parent: animation,
                  curve: widget.curve,
                  reverseCurve: widget.reverseCurve,
                ),
              ),
              child: child,
            );
          } else {
            return SlideTransition(
              position: Tween(
                begin: widget.beginOffset,
                end: widget.endOffset,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: widget.curve,
                  reverseCurve: widget.reverseCurve,
                ),
              ),
              child: child,
            );
          }
        },
        child: widget.child,
      );
}

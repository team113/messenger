import 'package:flutter/material.dart';

class AnimatedClipRRect extends ImplicitlyAnimatedWidget {
  const AnimatedClipRRect({
    super.key,
    super.curve,
    required super.duration,
    super.onEnd,
    required this.child,
    this.borderRadius = BorderRadius.zero,
  });

  final BorderRadius borderRadius;
  final Widget child;

  @override
  ImplicitlyAnimatedWidgetState<AnimatedClipRRect> createState() =>
      _AnimatedClipRRectState();
}

class _AnimatedClipRRectState
    extends ImplicitlyAnimatedWidgetState<AnimatedClipRRect> {
  Tween<BorderRadius>? _borderRadius;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _borderRadius = visitor(
      _borderRadius,
      widget.borderRadius,
      (dynamic value) => Tween<BorderRadius>(begin: value as BorderRadius),
    ) as Tween<BorderRadius>?;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _borderRadius?.evaluate(animation),
      child: widget.child,
    );
  }
}

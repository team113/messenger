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

import 'package:flutter/material.dart';

/// Animated transformation translation of the provided [child].
class AnimatedTransform extends ImplicitlyAnimatedWidget {
  const AnimatedTransform({
    Key? key,
    required this.offset,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.linear,
    void Function()? onEnd,
    required this.child,
  }) : super(key: key, curve: curve, duration: duration, onEnd: onEnd);

  /// Initial [Offset] of the [child].
  final Offset offset;

  /// [Widget] to transform around.
  final Widget child;

  @override
  ImplicitlyAnimatedWidgetState<AnimatedTransform> createState() =>
      _AnimatedTransformState();
}

/// State of an [AnimatedTransform] maintaining its [_animation] and
/// [_transform].
class _AnimatedTransformState
    extends ImplicitlyAnimatedWidgetState<AnimatedTransform> {

  /// [Animation] ot this [AnimatedTransform];
  late Animation<Offset> _animation;

  /// [Tween] ot this [_animation];
  Tween<Offset>? _transform;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _transform = visitor(
      _transform,
      widget.offset,
      (dynamic value) => Tween<Offset>(begin: value as Offset),
    ) as Tween<Offset>?;
  }

  @override
  void didUpdateTweens() {
    _animation = animation.drive(_transform!);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: _animation.value,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

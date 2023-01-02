// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

/// Animated translation of the provided [child] on the [offset] changes.
class AnimatedOffset extends ImplicitlyAnimatedWidget {
  const AnimatedOffset({
    Key? key,
    required this.offset,
    required this.child,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.linear,
    void Function()? onEnd,
  }) : super(key: key, curve: curve, duration: duration, onEnd: onEnd);

  /// [Offset] to apply to the [child].
  final Offset offset;

  /// [Widget] to offset.
  final Widget child;

  @override
  ImplicitlyAnimatedWidgetState<AnimatedOffset> createState() =>
      _AnimatedOffsetState();
}

/// State of an [AnimatedOffset] maintaining its [_animation] and [_transform].
class _AnimatedOffsetState
    extends ImplicitlyAnimatedWidgetState<AnimatedOffset> {
  /// [Animation] animating the [Offset] changes.
  late Animation<Offset> _animation;

  /// [Tween] to drive the [_animation] with.
  Tween<Offset>? _transform;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _transform = visitor(
      _transform,
      widget.offset,
      (value) => Tween<Offset>(begin: value as Offset),
    ) as Tween<Offset>?;
  }

  @override
  void didUpdateTweens() => _animation = animation.drive(_transform!);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) =>
          Transform.translate(offset: _animation.value, child: child!),
      child: widget.child,
    );
  }
}

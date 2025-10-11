// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

/// Animated translation of the provided [child] on the [offset] changes.
class AnimatedOffset extends ImplicitlyAnimatedWidget {
  const AnimatedOffset({
    super.key,
    required this.offset,
    required this.child,
    super.duration = const Duration(milliseconds: 250),
    super.curve = Curves.linear,
    super.onEnd,
  });

  /// Pixel offset to apply to the [child].
  final Offset offset;

  /// The widget to translate.
  final Widget child;

  @override
  ImplicitlyAnimatedWidgetState<AnimatedOffset> createState() =>
      _AnimatedOffsetState();
}

class _AnimatedOffsetState
    extends ImplicitlyAnimatedWidgetState<AnimatedOffset> {
  Tween<Offset>? _offsetTween;
  late Animation<Offset> _offsetAnimation;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _offsetTween = visitor(
      _offsetTween,
      widget.offset,
      (dynamic value) => Tween<Offset>(begin: value as Offset),
    ) as Tween<Offset>?;
  }

  @override
  void didUpdateTweens() {
    // `animation` is provided by ImplicitlyAnimatedWidgetState and already
    // wraps the controller with the given `curve`.
    _offsetAnimation = animation.drive(_offsetTween!);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (_, child) =>
          Transform.translate(offset: _offsetAnimation.value, child: child),
      child: widget.child,
    );
  }
}
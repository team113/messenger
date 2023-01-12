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

// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:flutter/scheduler.dart';

/// Animated rectangular transform of the provided [child].
class AnimatedTransition extends StatefulWidget {
  const AnimatedTransition({
    super.key,
    required this.beginRect,
    required this.endRect,
    required this.child,
    this.onEnd,
    this.curve,
    this.duration = const Duration(milliseconds: 200),
  });

  /// Initial [Rect] this [child] takes.
  final Rect beginRect;

  /// Target [Rect] to animate this [child] to.
  final Rect endRect;

  /// Callback, called when the animation ends.
  final VoidCallback? onEnd;

  /// [Widget] to transform around.
  final Widget child;

  /// [Curve] of the animation.
  final Curve? curve;

  /// [Duration] of the animation.
  final Duration duration;

  @override
  State<AnimatedTransition> createState() => AnimatedTransitionState();
}

/// State of an [AnimatedTransition] changing its [rect].
class AnimatedTransitionState extends State<AnimatedTransition>
    with SingleTickerProviderStateMixin {
  /// [Rect] that [AnimatedTransition.child] occupies.
  late Rect _rect;

  /// Indicator whether the [_rect] has been already updated in the current
  /// frame.
  ///
  /// Used to fix possible double [AnimatedTransition.onEnd] callback invoking.
  bool _updated = false;

  /// Sets the provided [rect] as the current of this [AnimatedTransition].
  set rect(Rect rect) {
    if (mounted && _rect != rect) {
      setState(() {
        _rect = rect;
        _updated = true;
      });

      SchedulerBinding.instance.addPostFrameCallback((_) {
        _updated = false;
      });
    }
  }

  @override
  void initState() {
    _rect = widget.beginRect;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _rect = widget.endRect);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned.fromRect(
          rect: _rect,
          duration: widget.duration,
          curve: widget.curve ?? Curves.linear,
          onEnd: _updated ? null : widget.onEnd,
          child: widget.child,
        ),
      ],
    );
  }
}

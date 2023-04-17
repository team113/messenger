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
    Key? key,
    required this.beginRect,
    required this.endRect,
    required this.child,
    this.onEnd,
    this.curve,
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);

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
  late Rect rect;

  /// Indicator whether the [rect] updated in the current frame.
  ///
  /// Used to disable [AnimatedTransition.onEnd] callback calling if `true`.
  bool _updated = false;

  @override
  void initState() {
    rect = widget.beginRect;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => rect = widget.endRect);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned.fromRect(
          rect: rect,
          duration: widget.duration,
          curve: widget.curve ?? Curves.linear,
          onEnd: () {
            if (!_updated) {
              widget.onEnd?.call();
            }
          },
          child: widget.child,
        ),
      ],
    );
  }

  /// Updates the [rect] value with the provided [Rect].
  void updateRect(Rect rect) {
    if (mounted && this.rect != rect) {
      setState(() {
        this.rect = rect;
        _updated = true;
      });

      SchedulerBinding.instance.addPostFrameCallback((_) {
        _updated = false;
      });
    }
  }
}

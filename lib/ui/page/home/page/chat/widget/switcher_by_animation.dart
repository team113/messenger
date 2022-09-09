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

/// [animation] is equal to [AnimationStatus.dismissed] then display [childBeforeAnimation].
/// [animation] is equal to [AnimationStatus.completed] then display [childAfterAnimation].
/// [animation] is null display [childAfterAnimation].
class SwitcherByAnimation extends StatefulWidget {
  const SwitcherByAnimation({
    super.key,
    required this.animation,
    required this.childBeforeAnimation,
    required this.childAfterAnimation,
  });

  /// Animation controller.
  final AnimationController? animation;

  /// [Widget] at the start of the animation.
  final Widget childBeforeAnimation;

  /// [Widget] at the end of the animation.
  final Widget childAfterAnimation;

  @override
  State<SwitcherByAnimation> createState() => _SwitcherByAnimationState();
}

class _SwitcherByAnimationState extends State<SwitcherByAnimation> {
  @override
  void initState() {
    super.initState();
    widget.animation?.addStatusListener(_listenStatusAnimation);
  }

  @override
  void dispose() {
    widget.animation?.removeStatusListener(_listenStatusAnimation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animation == null || widget.animation?.isCompleted == true) {
      return widget.childAfterAnimation;
    } else {
      return widget.childBeforeAnimation;
    }
  }

  void _listenStatusAnimation(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        // Show [childAfterAnimation].
      });
    } else if (status == AnimationStatus.dismissed) {
      setState(() {
        // Show [childBeforeAnimation].
      });
    }
  }
}

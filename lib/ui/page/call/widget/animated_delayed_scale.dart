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

/// [AnimatedScale] with an optional delay.
class AnimatedDelayedScale extends StatefulWidget {
  const AnimatedDelayedScale({
    Key? key,
    this.delay = Duration.zero,
    this.beginScale = 0,
    this.endScale = 1,
    this.duration = const Duration(milliseconds: 300),
    required this.child,
  }) : super(key: key);

  /// [Duration] of the delay.
  final Duration delay;

  /// [Duration] of the scaling animation.
  final Duration duration;

  /// Initial scale of [child].
  final double beginScale;

  /// Target scale of [child].
  final double endScale;

  /// [Widget] to scale.
  final Widget child;

  @override
  State<AnimatedDelayedScale> createState() => _AnimatedDelayedScaleState();
}

/// State of an [AnimatedDelayedScale] maintaining the [scale].
class _AnimatedDelayedScaleState extends State<AnimatedDelayedScale> {
  /// Current scale value.
  late double scale;

  @override
  void initState() {
    super.initState();

    scale = widget.beginScale;
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => scale = widget.endScale);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: widget.duration,
      scale: scale,
      curve: Curves.ease,
      child: widget.child,
    );
  }
}

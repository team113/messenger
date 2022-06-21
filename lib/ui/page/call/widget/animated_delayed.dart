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

/// Delayed animation widget.
class AnimatedDelayed extends StatefulWidget {
  const AnimatedDelayed({
    Key? key,
    required this.delay,
    required this.duration,
    required this.child,
  }) : super(key: key);

  /// [Duration] of animation.
  final Duration duration;

  /// [Duration] of delay.
  final Duration delay;

  /// Child [Widget].
  final Widget child;

  @override
  State<AnimatedDelayed> createState() => _AnimatedDelayedState();
}

/// [State] of [AnimatedDelayed].
class _AnimatedDelayedState extends State<AnimatedDelayed> {
  /// [Timer] of animation delay.
  late final Timer _timer;

  /// Indicator whether child widget should be displayed or not.
  bool show = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer(widget.delay, () {
      if (mounted) {
        setState(() => show = true);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: widget.duration,
        child: show ? widget.child : Container(),
      );
}

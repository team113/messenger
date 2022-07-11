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

/// [AnimatedSwitcher] with an optional delay.
class AnimatedDelayed extends StatefulWidget {
  const AnimatedDelayed({
    Key? key,
    this.delay = Duration.zero,
    required this.duration,
    required this.child,
  }) : super(key: key);

  /// [Duration] over which to animate the appearing.
  final Duration duration;

  /// [Duration] of a delay.
  final Duration delay;

  /// [Widget] to appear.
  final Widget child;

  @override
  State<AnimatedDelayed> createState() => _AnimatedDelayedState();
}

/// State of an [AnimatedDelayedScale] maintaining the [show].
class _AnimatedDelayedState extends State<AnimatedDelayed> {
  /// Current show value.
  bool show = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => show = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.duration,
      child: show ? widget.child : Container(),
    );
  }
}

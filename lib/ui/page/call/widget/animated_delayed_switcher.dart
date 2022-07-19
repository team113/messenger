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

/// [AnimatedSwitcher] with an optional [delay].
class AnimatedDelayedSwitcher extends StatefulWidget {
  const AnimatedDelayedSwitcher({
    Key? key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    required this.child,
  }) : super(key: key);

  /// [Duration] of the delay.
  final Duration delay;

  /// [Duration] of the switching animation.
  final Duration duration;

  /// [Widget] to switch to.
  final Widget child;

  @override
  State<AnimatedDelayedSwitcher> createState() =>
      _AnimatedDelayedSwitcherState();
}

/// [State] of an [AnimatedDelayedSwitcher] switching the [Widget].
class _AnimatedDelayedSwitcherState extends State<AnimatedDelayedSwitcher> {
  /// Indicator whether [AnimatedSwitcher] should be enabled.
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _show = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: widget.duration,
        child: _show ? widget.child : Container(),
      );
}

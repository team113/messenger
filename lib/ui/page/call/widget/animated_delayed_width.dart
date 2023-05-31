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

/// [AnimatedContainer] changing its width.
class AnimatedDelayedWidth extends StatefulWidget {
  const AnimatedDelayedWidth({
    super.key,
    this.delay = Duration.zero,
    required this.beginWidth,
    required this.endWidth,
    this.duration = const Duration(milliseconds: 300),
  });

  /// [Duration] of the delay.
  final Duration delay;

  /// [Duration] of the [AnimatedContainer].
  final Duration duration;

  /// Initial width of the [AnimatedContainer].
  final double beginWidth;

  /// Target width of the [AnimatedContainer].
  final double endWidth;

  @override
  State<AnimatedDelayedWidth> createState() => _AnimatedDelayedWidthState();
}

/// State of an [AnimatedDelayedWidth] maintaining its [width].
class _AnimatedDelayedWidthState extends State<AnimatedDelayedWidth> {
  /// Current width value.
  late double width;

  @override
  void initState() {
    super.initState();

    width = widget.beginWidth;
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => width = widget.endWidth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.duration,
      width: width,
      curve: Curves.ease,
    );
  }
}

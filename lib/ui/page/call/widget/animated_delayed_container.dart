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

/// [AnimatedContainer] changing its width.
class AnimatedDelayedWidth extends StatefulWidget {
  const AnimatedDelayedWidth({
    Key? key,
    this.delay = Duration.zero,
    this.beginWidth,
    this.endWidth,
    this.beginColor,
    this.endColor,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  /// [Duration] of the delay.
  final Duration delay;

  /// [Duration] of the [AnimatedContainer].
  final Duration duration;

  /// Initial width of the [AnimatedContainer].
  final double? beginWidth;

  /// Target width of the [AnimatedContainer].
  final double? endWidth;

  final Color? beginColor;
  final Color? endColor;

  @override
  State<AnimatedDelayedWidth> createState() => _AnimatedDelayedWidthState();
}

/// State of an [AnimatedDelayedWidth] maintaining the [width].
class _AnimatedDelayedWidthState extends State<AnimatedDelayedWidth> {
  /// Current width value.
  late double? width;

  late Color? color;

  @override
  void initState() {
    super.initState();

    width = widget.beginWidth;
    color = widget.beginColor;

    Future.delayed(widget.delay, () {
      if (mounted) {
        width = widget.endWidth;
        color = widget.endColor;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.duration,
      width: width,
      color: color,
      curve: Curves.ease,
    );
  }
}

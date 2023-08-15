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
import 'package:get/get.dart';

import '/themes.dart';

/// Animation of highlighting.
class HighlightAnimation extends StatefulWidget {
  const HighlightAnimation({
    super.key,
    required this.isHighlighted,
  });

  /// Indicator whether this [FadeTransition] animation should play.
  final bool isHighlighted;

  @override
  State<HighlightAnimation> createState() => _HighlightAnimationState();
}

/// State of [HighlightAnimation] maintaining its [AnimationController].
class _HighlightAnimationState extends State<HighlightAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: 400.milliseconds,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    if (widget.isHighlighted) {
      _controller.forward().then((value) =>
          Future.delayed(const Duration(milliseconds: 500))
              .then((value) => _controller.reverse()));
    }
    return FadeTransition(
      opacity: _animation,
      child: Container(
        color: style.colors.primaryOpacity20,
        padding: const EdgeInsets.fromLTRB(8, 1.5, 8, 1.5),
      ),
    );
  }
}

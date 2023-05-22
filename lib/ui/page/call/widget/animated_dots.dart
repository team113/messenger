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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/themes.dart';

/// [Text] represented three dots that change their count over [duration].
class AnimatedDots extends StatefulWidget {
  const AnimatedDots({
    super.key,
    this.duration = const Duration(milliseconds: 250),
  });

  /// [Duration] over which the count of dots is changed.
  final Duration duration;

  @override
  State<AnimatedDots> createState() => _AnimatedDotsState();
}

/// State of an [AnimatedDots] used to animate the dots.
class _AnimatedDotsState extends State<AnimatedDots> {
  /// Count of dots to display.
  int _count = 0;

  /// Periodic [Timer] used to increase the [_count].
  late final Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      setState(() => ++_count);
      if (_count > 3) {
        _count = 0;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return SizedBox(
      width: 13,
      child: Text(
        'dot'.l10n * _count,
        style: context.textTheme.bodyLarge!.copyWith(
          color: style.colors.onPrimary,
        ),
      ),
    );
  }
}

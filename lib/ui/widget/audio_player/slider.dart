// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/themes.dart';

/// Slider for audio rewind.
class SeekSlider extends StatelessWidget {
  const SeekSlider({
    super.key,
    required this.position,
    required this.duration,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  /// Current audio position.
  final Duration position;

  /// Total audio duration.
  final Duration duration;

  /// Callback, called on slider drag.
  final ValueChanged<double>? onChanged;

  /// Callback, called on slider drag start.
  final ValueChanged<double>? onChangeStart;

  /// Callback, called on slider drag end.
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final double max = duration.inMilliseconds.toDouble();
    final double value = position.inMilliseconds.toDouble().clamp(
      0.0,
      max > 0 ? max : 0.0,
    );

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2.0,
        activeTrackColor: style.colors.primary,
        inactiveTrackColor: style.colors.secondaryHighlightDarkest,
        thumbColor: style.colors.primary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
      ),
      child: SizedBox(
        height: 17,
        child: Slider(
          value: value,
          max: max > 0 ? max : 1.0,
          onChangeStart: onChangeStart,
          onChangeEnd: onChangeEnd,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

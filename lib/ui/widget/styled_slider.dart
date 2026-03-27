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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';

import '/themes.dart';
import '/util/platform_utils.dart';

/// [FlutterSlider] styled and refactor to be as handy as possible.
class StyledSlider<T> extends StatefulWidget {
  const StyledSlider({
    super.key,
    required this.value,
    required this.values,
    this.onCompleted,
    required this.labelBuilder,
  });

  /// Currently selected value from [values].
  final T value;

  /// [T] values to switch between.
  final List<T> values;

  /// Callback, called when the provided [T] is selected.
  final void Function(T)? onCompleted;

  /// Builder building a label to the provided value.
  final Widget Function(double percent, T value) labelBuilder;

  @override
  State<StyledSlider<T>> createState() => _StyledSliderState<T>();
}

/// State of a [StyledSlider] used to keep and compare the previous value.
class _StyledSliderState<T> extends State<StyledSlider<T>> {
  /// Previously selected [T] value.
  T? _previous;

  @override
  void initState() {
    _previous = widget.value;
    super.initState();
  }

  @override
  void didUpdateWidget(StyledSlider<T> oldWidget) {
    _previous = widget.value;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final current =
        (100 *
        (1 / (widget.values.length - 1)) *
        widget.values.indexOf(_previous ?? widget.value));

    return SizedBox(
      height: 70,
      child: Transform.translate(
        offset: Offset(0, 12),
        child: FlutterSlider(
          handlerHeight: 24,
          handler: FlutterSliderHandler(child: const SizedBox()),
          values: [current],
          tooltip: FlutterSliderTooltip(disabled: true),
          fixedValues: widget.values.mapIndexed((i, e) {
            return FlutterSliderFixedValue(
              percent: ((i / (widget.values.length - 1)) * 100).round(),
              value: e,
            );
          }).toList(),
          trackBar: FlutterSliderTrackBar(
            activeTrackBarHeight: 3,
            inactiveTrackBarHeight: 3,
            inactiveTrackBar: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: style.colors.secondaryHighlightDarkest,
            ),
            activeTrackBar: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: style.colors.primary,
            ),
          ),
          onDragging: (i, lower, upper) {
            if (lower is T) {
              if (lower != _previous) {
                setState(() => _previous = lower);
                PlatformUtils.haptic(kind: HapticKind.light);
              }
            }
          },
          onDragCompleted: (i, lower, upper) {
            if (lower is T) {
              widget.onCompleted?.call(lower);
            } else if (upper is T) {
              widget.onCompleted?.call(upper);
            }
          },
          hatchMark: FlutterSliderHatchMark(
            labelsDistanceFromTrackBar: 0,
            labels: widget.values.mapIndexed((i, e) {
              final percent = ((i / (widget.values.length - 1)) * 100);
              final selected =
                  widget.values.indexOf(_previous ?? widget.value) >= i;

              return FlutterSliderHatchMarkLabel(
                percent: percent,
                label: Transform.translate(
                  offset: Offset(0, 1.5),
                  child: FractionalTranslation(
                    translation: Offset(0, -0.5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        widget.labelBuilder(percent, e),
                        SizedBox(height: 12),
                        Container(
                          width: 3,
                          height: 8,
                          decoration: BoxDecoration(
                            color: selected
                                ? style.colors.primary
                                : style.colors.secondaryHighlightDarkest,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

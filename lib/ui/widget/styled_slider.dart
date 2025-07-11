// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '../../util/platform_utils.dart';
import '/themes.dart';

class StyledSlider<T> extends StatefulWidget {
  const StyledSlider({
    super.key,
    required this.value,
    required this.values,
    this.onCompleted,
    required this.labelBuilder,
  });

  final T value;
  final List<T> values;
  final void Function(T)? onCompleted;
  final Widget Function(double percent, T value) labelBuilder;

  @override
  State<StyledSlider<T>> createState() => _StyledSliderState<T>();
}

class _StyledSliderState<T> extends State<StyledSlider<T>> {
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
        widget.values.indexOf(widget.value));

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
              color: style.colors.onBackgroundOpacity13,
            ),
            activeTrackBar: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: style.colors.primaryHighlight,
            ),
          ),
          onDragging: (i, lower, upper) {
            T? real;

            if (lower is T) {
              real = lower;
            } else if (upper is T) {
              real = upper;
            }

            if (real != _previous) {
              _previous = real;
              PlatformUtils.haptic(kind: HapticKind.light);
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
            labelsDistanceFromTrackBar: -48,
            labels: widget.values.mapIndexed((i, e) {
              final percent = ((i / (widget.values.length - 1)) * 100);

              return FlutterSliderHatchMarkLabel(
                percent: percent,
                label: widget.labelBuilder(percent, e),
              );
            }).toList(),
            // labels: [
            //   FlutterSliderHatchMarkLabel(
            //     percent: 0,
            //     label: Text(
            //       textAlign: TextAlign.center,
            //       'label_disabled'.l10n,
            //       style: style.fonts.smaller.regular.secondary,
            //     ),
            //   ),
            //   FlutterSliderHatchMarkLabel(
            //     percent: 25,
            //     label: Text(
            //       textAlign: TextAlign.center,
            //       'label_low'.l10n,
            //       style: style.fonts.smaller.regular.secondary,
            //     ),
            //   ),
            //   FlutterSliderHatchMarkLabel(
            //     percent: 50,
            //     label: Text(
            //       textAlign: TextAlign.center,
            //       'label_medium'.l10n,
            //       style: style.fonts.smaller.regular.secondary,
            //     ),
            //   ),
            //   FlutterSliderHatchMarkLabel(
            //     percent: 75,
            //     label: Text(
            //       textAlign: TextAlign.center,
            //       'label_high'.l10n,
            //       style: style.fonts.smaller.regular.secondary,
            //     ),
            //   ),
            //   FlutterSliderHatchMarkLabel(
            //     percent: 100,
            //     label: Text(
            //       textAlign: TextAlign.center,
            //       'label_very_high'.l10n,
            //       style: style.fonts.smaller.regular.secondary,
            //     ),
            //   ),
            // ],
          ),
        ),
      ),
    );
  }
}

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

import 'dart:math';

import 'package:flutter/material.dart';
import '/ui/page/call/widget/fit_view.dart';

/// Places [children] into a shrinkable [Wrap].
class FitWrap extends StatelessWidget {
  const FitWrap({
    Key? key,
    required this.children,
    required this.maxSize,
    this.axis = Axis.horizontal,
    this.spacing = 1,
    this.alignment = WrapAlignment.center,
  }) : super(key: key);

  /// Widgets to put inside a [Wrap].
  final List<Widget> children;

  /// [Axis] of a [Wrap].
  final Axis axis;

  /// Maximum size in pixels of a [Wrap]ped [children].
  final double maxSize;

  /// Space between [children].
  final double spacing;

  /// Alignment of the [children].
  final WrapAlignment alignment;

  /// Returns calculated size of a [FitWrap] with [maxSize], [constraints],
  /// [axis] and children [length].
  static double calculateSize({
    required double maxSize,
    required Size constraints,
    required Axis axis,
    required int length,
  }) {
    var size = min(
      maxSize,
      axis == Axis.horizontal
          ? constraints.height / length
          : constraints.width / length,
    );

    if (axis == Axis.horizontal) {
      if (size * length >= constraints.height) {
        size = constraints.width / 2;
      }
    } else {
      if (size * length >= constraints.width) {
        size = constraints.height / 2;
      }
    }

    return size;
  }

  static bool useFitView({
    required double maxSize,
    required Size constraints,
    required Axis axis,
    required int length,
  }) {
    var size = min(
      maxSize,
      axis == Axis.horizontal
          ? constraints.height / length
          : constraints.width / length,
    );

    if (axis == Axis.horizontal) {
      return (size * length >= constraints.height);
    } else {
      return (size * length >= constraints.width);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double size = calculateSize(
        maxSize: maxSize,
        constraints: Size(constraints.maxWidth, constraints.maxHeight),
        length: children.length,
        axis: axis,
      );

      bool fitView = useFitView(
        maxSize: maxSize,
        constraints: Size(constraints.maxWidth, constraints.maxHeight),
        length: children.length,
        axis: axis,
      );

      if (fitView) {
        return FitView(children: children);
      }

      return Wrap(
        direction: axis,
        alignment: alignment,
        runAlignment: alignment,
        spacing: spacing,
        runSpacing: spacing,
        children: children
            .map((e) => SizedBox(
                  width: axis == Axis.horizontal ? size : size - spacing,
                  height: axis == Axis.horizontal ? size - spacing : size,
                  child: e,
                ))
            .toList(),
      );
    });
  }
}

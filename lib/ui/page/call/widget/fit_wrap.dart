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

/// Places [children] into a shrinkable [Wrap].
class FitWrap extends StatelessWidget {
  const FitWrap({
    Key? key,
    required this.children,
    required this.maxSize,
    this.axis = Axis.horizontal,
  }) : super(key: key);

  /// Widgets to put inside a [Wrap].
  final List<Widget> children;

  /// [Axis] of a [Wrap].
  final Axis axis;

  /// Maximum size in pixels of a [Wrap]ped [children].
  final double maxSize;

  /// Returns calculated size of a [FitWrap] with [maxSize], [constraints],
  /// [axis] and children [length].
  static double calculateSize({
    required double maxSize,
    required Size constraints,
    required Axis axis,
    required int length,
  }) =>
      min(
        maxSize,
        axis == Axis.horizontal
            ? constraints.height / length
            : constraints.width / length,
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double size = calculateSize(
        maxSize: maxSize,
        constraints: Size(constraints.maxWidth, constraints.maxHeight),
        length: children.length,
        axis: axis,
      );

      return SizedBox(
        width: axis == Axis.horizontal ? size : double.infinity,
        height: axis == Axis.horizontal ? double.infinity : size,
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 1,
          runSpacing: 1,
          children: children
              .map((e) => SizedBox(
                    width: axis == Axis.horizontal ? size : size - 1,
                    height: axis == Axis.horizontal ? size - 1 : size,
                    child: e,
                  ))
              .toList(),
        ),
      );
    });
  }
}

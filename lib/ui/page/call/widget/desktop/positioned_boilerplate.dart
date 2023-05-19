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

import '../scaler.dart';

class PositionedBoilerplateWidget extends StatelessWidget {
  const PositionedBoilerplateWidget({
    super.key,
    required this.width,
    required this.height,
    this.child,
    this.left,
    this.right,
    this.top,
    this.bottom,
  });

  /// The widget contained by this widget
  final Widget? child;

  /// The distance between the left edge of the [PositionedBoilerplateWidget]
  /// and the left edge of the parent widget.
  final double? left;

  /// The distance between the right edge of the [PositionedBoilerplateWidget]
  /// and the right edge of the parent widget.
  final double? right;

  /// The distance between the top edge of the [PositionedBoilerplateWidget]
  /// and the top edge of the parent widget.
  final double? top;

  /// The distance between the bottom edge of the [PositionedBoilerplateWidget]
  /// and the bottom edge of the parent widget.
  final double? bottom;

  /// The width of the [PositionedBoilerplateWidget].
  final double width;

  /// The height of the [PositionedBoilerplateWidget].
  final double height;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left == null ? null : (left! - Scaler.size / 2),
      right: right == null ? null : (right! - Scaler.size / 2),
      top: top == null ? null : (top! - Scaler.size / 2),
      bottom: bottom == null ? null : (bottom! - Scaler.size / 2),
      child: SizedBox(
        width: width + Scaler.size,
        height: height + Scaler.size,
        child: child,
      ),
    );
  }
}

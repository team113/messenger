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

/// [Widget] which returns a [Scaler] scaling the minimized view.
class MinimizedScaler extends StatelessWidget {
  const MinimizedScaler({
    super.key,
    this.cursor = MouseCursor.defer,
    this.onDragUpdate,
    this.onDragEnd,
    this.width,
    this.height,
  });

  /// Interface for mouse cursor definitions.
  final MouseCursor cursor;

  /// Width of this [MinimizedScaler].
  final double? width;

  /// Height of this [MinimizedScaler].
  final double? height;

  /// Callback, called when dragging is updated.
  final dynamic Function(double, double)? onDragUpdate;

  /// Callback, called when dragging ends.
  final dynamic Function(DragEndDetails)? onDragEnd;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: Scaler(
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        width: width ?? Scaler.size,
        height: height ?? Scaler.size,
      ),
    );
  }
}

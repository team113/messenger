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
import 'package:messenger/themes.dart';

/// Draggable widget reporting delta of a dragging through [onDragUpdate]
/// callback.
class Scaler extends StatefulWidget {
  const Scaler({
    Key? key,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.width = size,
    this.height = size,
    this.opacity = 0,
  }) : super(key: key);

  /// Size of the draggable area, used by default on [width] and [height].
  static const double size = 20;

  /// Callback, called when dragging is started.
  final Function(DragStartDetails details)? onDragStart;

  /// Callback reporting the `x` and `y` drag deltas.
  final Function(double, double)? onDragUpdate;

  /// Callback, called when dragging is ended.
  final Function(DragEndDetails details)? onDragEnd;

  /// Width of the draggable area.
  final double width;

  /// Height of the draggable area.
  final double height;

  /// Opacity of the draggable area.
  final double opacity;

  @override
  State<Scaler> createState() => _ScalerState();
}

/// State of a [Scaler] used to set the initial dragging coordinates.
class _ScalerState extends State<Scaler> {
  /// Initial `x` coordinate of dragging.
  late double initX;

  /// Initial `y` coordinate of dragging.
  late double initY;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          initX = details.globalPosition.dx;
          initY = details.globalPosition.dy;
        });

        widget.onDragStart?.call(details);
      },
      onPanUpdate: (details) {
        var dx = details.globalPosition.dx - initX;
        var dy = details.globalPosition.dy - initY;
        initX = details.globalPosition.dx;
        initY = details.globalPosition.dy;
        widget.onDragUpdate?.call(dx, dy);
      },
      onPanEnd: widget.onDragEnd,
      child: Opacity(
        opacity: widget.opacity,
        child: Container(
          width: widget.width,
          height: widget.height,
          color: Theme.of(context).extension<Style>()!.secondaryAzure,
        ),
      ),
    );
  }
}

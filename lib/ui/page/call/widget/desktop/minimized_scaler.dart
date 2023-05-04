import 'package:flutter/material.dart';

import '../scaler.dart';

/// [Widget] which returns a [Scaler] scaling the minimized view.
class MinimizedScaler extends StatelessWidget {
  const MinimizedScaler({
    Key? key,
    this.cursor = MouseCursor.defer,
    this.onDragUpdate,
    this.onDragEnd,
    this.width,
    this.height,
  }) : super(key: key);

  /// Interface for mouse cursor definitions.
  final MouseCursor cursor;

  /// [Function] that gets called when dragging is updated.
  final Function(double, double)? onDragUpdate;

  /// [Function] that gets called when dragging ends.
  final dynamic Function(DragEndDetails)? onDragEnd;

  /// Width of this [MinimizedScaler].
  final double? width;

  /// Height of this [MinimizedScaler].
  final double? height;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: Scaler(
        key: key,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        width: width ?? Scaler.size,
        height: height ?? Scaler.size,
      ),
    );
  }
}

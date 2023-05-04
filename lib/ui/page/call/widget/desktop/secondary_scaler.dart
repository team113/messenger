import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller.dart';
import '../scaler.dart';

/// [Widget] that contains a [MouseRegion] and a [Scaler] widget.
///
/// It is used to resize a secondary video window.
class SecondaryScaler extends StatelessWidget {
  const SecondaryScaler({
    super.key,
    required this.draggedRenderer,
    this.cursor = MouseCursor.defer,
    this.onDragUpdate,
    this.onDragEnd,
    this.width,
    this.height,
  });

  /// Interface for mouse cursor definitions
  final MouseCursor cursor;

  /// [Rx] object that contains information about the renderer being dragged.
  final Rx<Participant?> draggedRenderer;

  /// [Function] that gets called when dragging is updated.
  final Function(double, double)? onDragUpdate;

  /// [Function] that gets called when dragging ends.
  final dynamic Function(DragEndDetails)? onDragEnd;

  /// Width of the [SecondaryScaler].
  final double? width;

  /// Height of the [SecondaryScaler].
  final double? height;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: draggedRenderer.value == null ? cursor : MouseCursor.defer,
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

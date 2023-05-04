import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../../../../util/platform_utils.dart';
import '../../controller.dart';
import '../scaler.dart';
import 'secondary_scaler.dart';

/// Handle with a drag-and-drop function that allows the user to resize and
/// manipulate user interface elements.
class BuildDragHandle extends StatelessWidget {
  const BuildDragHandle(
    this.height,
    this.width,
    this.alignment,
    this.draggedRenderer, {
    super.key,
    this.onDragUpdate,
    this.onDragEnd,
  });

  /// Alignment of the [SecondaryScaler].
  final Alignment alignment;

  /// Height of the [SecondaryScaler].
  final double height;

  /// Width of the [SecondaryScaler].
  final double width;

  /// [Function] that is responsible for handling the events of dragging
  /// an element on the screen, returning a callback function that will be
  /// called every time the user moves the element.
  final dynamic Function(double, double)? onDragUpdate;

  /// [Function] that is responsible for handling element dragging events
  /// is called only once at the moment when the user finishes dragging
  /// the element.
  final dynamic Function(DragEndDetails)? onDragEnd;

  /// Link to the item that is being dragged now.
  final Rx<Participant?> draggedRenderer;

  @override
  Widget build(BuildContext context) {
    Widget widget = const SizedBox();

    if (alignment == Alignment.centerLeft) {
      widget = SecondaryScaler(
        cursor: SystemMouseCursors.resizeLeftRight,
        height: height - Scaler.size,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.centerRight) {
      widget = SecondaryScaler(
        cursor: SystemMouseCursors.resizeLeftRight,
        height: height - Scaler.size,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.bottomCenter) {
      widget = SecondaryScaler(
        cursor: SystemMouseCursors.resizeUpDown,
        width: width - Scaler.size,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.topCenter) {
      widget = SecondaryScaler(
        cursor: SystemMouseCursors.resizeUpDown,
        width: width - Scaler.size,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.topLeft) {
      widget = SecondaryScaler(
        // TODO: https://github.com/flutter/flutter/issues/89351
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpLeftDownRight,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.topRight) {
      widget = SecondaryScaler(
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpRightDownLeft,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.bottomLeft) {
      widget = SecondaryScaler(
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpRightDownLeft,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.bottomRight) {
      widget = SecondaryScaler(
        // TODO: https://github.com/flutter/flutter/issues/89351
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpLeftDownRight,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    }

    return Align(alignment: alignment, child: widget);
  }
}

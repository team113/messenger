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
import 'package:get/get.dart';

import '../scaler.dart';
import '/ui/page/call/controller.dart';
import '/util/platform_utils.dart';
import 'secondary_scaler.dart';

/// Handle with a drag-and-drop function that allows the user to resize and
/// manipulate user interface elements.
class DragDropHandler extends StatelessWidget {
  const DragDropHandler(
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

  /// [Rx] participant that contains information about the renderer being
  /// dragged.
  final Rx<Participant?> draggedRenderer;

  /// Callback reporting the `x` and `y` drag deltas.
  final dynamic Function(double, double)? onDragUpdate;

  /// Callback, called when dragging ends.
  final dynamic Function(DragEndDetails)? onDragEnd;

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

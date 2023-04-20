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

import '../controller.dart';
import '/util/platform_utils.dart';

import 'desktop_scaler.dart';
import 'scaler.dart';

class DesktopBuildDragHandle extends StatelessWidget {
  const DesktopBuildDragHandle({
    Key? key,
    required this.alignment,
    required this.height,
    required this.width,
  }) : super(key: key);

  /// Alignment of the [SecondaryScalerWidget].
  final Alignment alignment;

  /// Height of the [SecondaryScalerWidget].
  final double height;

  /// Width of the [SecondaryScalerWidget].
  final double width;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      builder: (CallController c) {
        Widget widget = Container();

        if (alignment == Alignment.centerLeft) {
          widget = SecondaryScalerWidget(
            cursor: SystemMouseCursors.resizeLeftRight,
            height: height - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              x: ScaleModeX.left,
              dx: dx,
            ),
          );
        } else if (alignment == Alignment.centerRight) {
          widget = SecondaryScalerWidget(
            cursor: SystemMouseCursors.resizeLeftRight,
            height: height - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              x: ScaleModeX.right,
              dx: -dx,
            ),
          );
        } else if (alignment == Alignment.bottomCenter) {
          widget = SecondaryScalerWidget(
            cursor: SystemMouseCursors.resizeUpDown,
            width: width - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.bottom,
              dy: -dy,
            ),
          );
        } else if (alignment == Alignment.topCenter) {
          widget = SecondaryScalerWidget(
            cursor: SystemMouseCursors.resizeUpDown,
            width: width - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.top,
              dy: dy,
            ),
          );
        } else if (alignment == Alignment.topLeft) {
          widget = SecondaryScalerWidget(
            // TODO: https://github.com/flutter/flutter/issues/89351
            cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                ? SystemMouseCursors.resizeRow
                : SystemMouseCursors.resizeUpLeftDownRight,
            width: Scaler.size * 2,
            height: Scaler.size * 2,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.top,
              x: ScaleModeX.left,
              dx: dx,
              dy: dy,
            ),
          );
        } else if (alignment == Alignment.topRight) {
          widget = SecondaryScalerWidget(
            cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                ? SystemMouseCursors.resizeRow
                : SystemMouseCursors.resizeUpRightDownLeft,
            width: Scaler.size * 2,
            height: Scaler.size * 2,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.top,
              x: ScaleModeX.right,
              dx: -dx,
              dy: dy,
            ),
          );
        } else if (alignment == Alignment.bottomLeft) {
          widget = SecondaryScalerWidget(
            cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                ? SystemMouseCursors.resizeRow
                : SystemMouseCursors.resizeUpRightDownLeft,
            width: Scaler.size * 2,
            height: Scaler.size * 2,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.bottom,
              x: ScaleModeX.left,
              dx: dx,
              dy: -dy,
            ),
          );
        } else if (alignment == Alignment.bottomRight) {
          widget = SecondaryScalerWidget(
            // TODO: https://github.com/flutter/flutter/issues/89351
            cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                ? SystemMouseCursors.resizeRow
                : SystemMouseCursors.resizeUpLeftDownRight,
            width: Scaler.size * 2,
            height: Scaler.size * 2,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.bottom,
              x: ScaleModeX.right,
              dx: -dx,
              dy: -dy,
            ),
          );
        }

        return Align(alignment: alignment, child: widget);
      },
    );
  }
}

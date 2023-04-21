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
import 'scaler.dart';

/// Returns a [Scaler] scaling the secondary view.
class SecondaryScalerWidget extends StatelessWidget {
  const SecondaryScalerWidget({
    super.key,
    this.cursor = MouseCursor.defer,
    this.onDrag,
    this.width,
    this.height,
  });

  /// Interface for mouse cursor definitions
  final MouseCursor cursor;

  /// Calculates the corresponding values according to the enabled dragging.
  final Function(double, double)? onDrag;

  /// Width of the [SecondaryScalerWidget].
  final double? width;

  /// Height of the [SecondaryScalerWidget].
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Obx(() {
        return MouseRegion(
          cursor: c.draggedRenderer.value == null ? cursor : MouseCursor.defer,
          child: Scaler(
            key: key,
            onDragUpdate: onDrag,
            onDragEnd: (_) {
              c.updateSecondaryAttach();
            },
            width: width ?? Scaler.size,
            height: height ?? Scaler.size,
          ),
        );
      });
    });
  }
}

/// Returns a [Scaler] scaling the minimized view.
class MinimizedScalerWidget extends StatelessWidget {
  const MinimizedScalerWidget({
    Key? key,
    required this.onDrag,
    this.cursor = MouseCursor.defer,
    this.width,
    this.height,
  }) : super(key: key);

  /// Interface for mouse cursor definitions.
  final MouseCursor cursor;

  /// Calculates the corresponding values according to the enabled dragging.
  final Function(double, double) onDrag;

  /// Width of this [MinimizedScalerWidget].
  final double? width;

  /// Height of this [MinimizedScalerWidget].
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return MouseRegion(
        cursor: cursor,
        child: Scaler(
          key: key,
          onDragUpdate: onDrag,
          onDragEnd: (_) {
            c.updateSecondaryAttach();
          },
          width: width ?? Scaler.size,
          height: height ?? Scaler.size,
        ),
      );
    });
  }
}

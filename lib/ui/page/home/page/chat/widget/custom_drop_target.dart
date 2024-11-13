// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

/// Custom wrapper around [DropRegion] to simplify usage.
class CustomDropTarget extends StatelessWidget {
  const CustomDropTarget({
    super.key,
    required this.onPerformDrop,
    this.onDropEnter,
    this.onDropLeave,
    required this.child,
  });

  /// [Widget] to wrap this [CustomDropTarget] around.
  final Widget child;

  /// Callback, called when [DropRegion.onPerformDrop].
  final void Function(PerformDropEvent) onPerformDrop;

  /// Callback, called when [DropRegion.onDropEnter].
  final void Function(DropEvent)? onDropEnter;

  /// Callback, called when [DropRegion.onDropLeave].
  final void Function(DropEvent)? onDropLeave;

  @override
  Widget build(BuildContext context) {
    return DropRegion(
      formats: Formats.standardFormats,
      onDropOver: (event) =>
          event.session.allowedOperations.firstOrNull ?? DropOperation.none,
      onPerformDrop: (event) async {
        onPerformDrop(event);
      },
      onDropEnter: onDropEnter,
      onDropLeave: onDropLeave,
      child: child,
    );
  }
}

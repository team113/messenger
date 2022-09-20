// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'custom_selection_container.dart';

/// [CustomSelectionText] copies the selected text.
class CustomSelectionText extends StatelessWidget {
  const CustomSelectionText({
    Key? key,
    required this.selections,
    required this.position,
    required this.type,
    this.isTapMessage,
    this.animation,
    required this.child,
  }) : super(key: key);

  /// Storage [SelectionData].
  final Map<int, List<SelectionData>>? selections;

  /// Clicking on [SelectionData].
  final Rx<bool>? isTapMessage;

  /// Message position index.
  /// 
  /// It is sorted.
  final int? position;

  /// Selected text type.
  ///
  /// Sorting is by [SelectionItem.index] for each [position].
  final SelectionItem? type;

  /// Controller for an animation.
  final AnimationController? animation;

  /// [Widget] in which there will be text to selection.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (type != null && selections != null && position != null) {
      return Listener(
        onPointerDown: (_) => isTapMessage?.value = true,
        onPointerUp: (_) => isTapMessage?.value = false,
        onPointerCancel: (_) => isTapMessage?.value = false,
        child: CustomSelectionContainer(
          selections: selections!,
          position: position!,
          type: type!,
          animation: animation,
          child: child,
        ),
      );
    } else {
      return child;
    }
  }
}

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

import '../controller.dart';

/// [child] in which the text will be selected
/// and catch the intent of copying the text.
class CustomSelectionArea extends StatelessWidget {
  const CustomSelectionArea({
    super.key,
    required this.controller,
    required this.child,
  });

  /// Сontroller passed to [_CopySelectionAction]
  /// to copy text to [Clipboard].
  final ChatController controller;

  /// Any [Text] in [child] will be selectable
  /// unless explicitly specified [SelectionContainer.disabled]
  /// above [Text].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        CopySelectionTextIntent: Action.overridable(
          defaultAction: _CopySelectionAction(controller),
          context: context,
        ),
      },
      child: SelectionArea(child: child),
    );
  }
}

/// Overridable copy [Action].
class _CopySelectionAction extends Action<CopySelectionTextIntent> {
  _CopySelectionAction(this.controller);

  /// Pass [controller.selectionText] to [controller.copyText].
  final ChatController controller;

  @override
  Future<void> invoke(_) async {
    final String clipboard = controller.selectionText;
    if (clipboard.isNotEmpty) {
      controller.copyText(clipboard.toString());
    }
  }
}

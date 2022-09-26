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

/// Area in which the text will be highlighted.
///
/// Overrides the copy action if [onCopy] is passed.
class CustomSelectionArea extends StatelessWidget {
  const CustomSelectionArea({
    super.key,
    this.onCopy,
    required this.child,
  });

  /// Callback when the [CopySelectionTextIntent] is to be performed.
  final void Function()? onCopy;

  /// [Widget] in which there will be text to selection.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final area = SelectionArea(child: child);
    if (onCopy == null) {
      return area;
    } else {
      return Actions(
        actions: <Type, Action<Intent>>{
          CopySelectionTextIntent: Action.overridable(
            defaultAction: _CopySelectionAction(onCopy!),
            context: context,
          ),
        },
        child: area,
      );
    }
  }
}

/// [Action] for an [Intent] that represents a user interaction that attempts to copy or cut the current selection in the field.
class _CopySelectionAction extends Action<CopySelectionTextIntent> {
  _CopySelectionAction(this.copyText);

  /// Callback when the [CopySelectionTextIntent] is to be performed.
  final void Function() copyText;

  @override
  Future<void> invoke(_) async => copyText();
}

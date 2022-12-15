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
import 'package:messenger/ui/widget/widget_button.dart';

import '/ui/widget/text_field.dart';

/// Button from the [ReactiveTextField].
class FieldButton extends StatelessWidget {
  const FieldButton({
    Key? key,
    this.onPressed,
    this.onTrailingPressed,
    this.text,
    this.style,
    this.hint,
    this.trailing,
    this.prefix,
  }) : super(key: key);

  /// Callback called when this [FieldButton] is pressed.
  final VoidCallback? onPressed;

  /// Callback called when the [trailing] is pressed.
  ///
  /// Does nothing if the [trailing] is `null`.
  final VoidCallback? onTrailingPressed;

  /// Optional label of this [FieldButton].
  final String? text;

  /// [TextStyle] of the [text].
  final TextStyle? style;

  /// Optional hint of this [FieldButton].
  final String? hint;

  /// Optional trailing [Widget].
  final Widget? trailing;

  /// Optional prefix [Widget].
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    final Widget field = WidgetButton(
      behavior: HitTestBehavior.deferToChild,
      onPressed: onPressed,
      child: IgnorePointer(
        child: ReactiveTextField(
          state: TextFieldState(
            text: text,
            editable: false,
          ),
          label: hint,
          trailing: trailing,
          prefix: prefix,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );

    if (trailing != null && onTrailingPressed != null) {
      return Stack(
        alignment: Alignment.centerRight,
        children: [
          field,
          WidgetButton(
            onPressed: onTrailingPressed,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 30,
              height: 30,
            ),
          ),
        ],
      );
    }

    return field;
  }
}

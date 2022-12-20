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

/// Button based on the [ReactiveTextField].
class FieldButton extends StatelessWidget {
  const FieldButton({
    Key? key,
    this.text,
    this.textAlign = TextAlign.start,
    this.hint,
    this.maxLines = 1,
    this.onPressed,
    this.onTrailingPressed,
    this.trailing,
    this.prefix,
    this.style,
  }) : super(key: key);

  /// Optional label of this [FieldButton].
  final String? text;

  /// [TextAlign] of the [text].
  final TextAlign textAlign;

  /// Optional hint of this [FieldButton].
  final String? hint;

  /// Maximum number of lines to show at one time, wrapping if necessary.
  final int? maxLines;

  /// Callback called when this [FieldButton] is pressed.
  final VoidCallback? onPressed;

  /// Callback called when the [trailing] is pressed.
  ///
  /// Does nothing if the [trailing] is `null`.
  final VoidCallback? onTrailingPressed;

  /// Optional trailing [Widget].
  final Widget? trailing;

  /// Optional prefix [Widget].
  final Widget? prefix;

  /// [TextStyle] of the [text].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    Widget widget = WidgetButton(
      behavior: HitTestBehavior.deferToChild,
      onPressed: onPressed,
      child: IgnorePointer(
        child: ReactiveTextField(
          textAlign: textAlign,
          state: TextFieldState(
            text: text,
            editable: false,
          ),
          label: hint,
          maxLines: maxLines,
          trailing: trailing,
          prefix: prefix,
          style: style,
        ),
      ),
    );

    if (trailing == null || onTrailingPressed == null) {
      return widget;
    }

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        widget,
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
}

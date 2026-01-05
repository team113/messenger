// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/themes.dart';
import 'field_button.dart';

/// Stylized [FieldButton] representing a single action.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.text = '',
    this.onPressed,
    this.trailing,
    this.danger = false,
  });

  /// Text to display in this [ActionButton].
  final String text;

  /// Trailing to display in this [ActionButton].
  final Widget? trailing;

  /// Callback, called when this [ActionButton] is pressed.
  final void Function()? onPressed;

  /// Indicator whether this [ActionButton] should be displayed in a danger
  /// (destructive) style.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: FieldButton(
        onPressed: onPressed,
        text: text,
        border: danger
            ? BorderSide(color: style.colors.danger, width: 0.5)
            : null,
        style: danger
            ? style.fonts.normal.regular.danger
            : style.fonts.normal.regular.primary,
        trailing: trailing,
      ),
    );
  }
}

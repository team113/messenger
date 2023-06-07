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

import '/themes.dart';
import 'field_button.dart';
import 'paddings.dart';

/// Stylized [FieldButton] representing a single action.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.text = '',
    this.onPressed,
    this.trailing,
  });

  /// Text to display in this [ActionButton].
  final String text;

  /// Trailing to display in this [ActionButton].
  final Widget? trailing;

  /// Callback, called when this [ActionButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: Insets.dense.add(const EdgeInsets.only(bottom: 8)),
      child: FieldButton(
        onPressed: onPressed,
        text: text,
        style: style.labelLarge.copyWith(color: style.colors.primary),
        trailing: trailing != null
            ? Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(scale: 1.15, child: trailing),
              )
            : null,
      ),
    );
  }
}

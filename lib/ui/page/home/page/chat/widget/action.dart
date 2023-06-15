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
import '/ui/page/home/page/my_profile/widget/field_button.dart';
import 'dense.dart';

/// [Widget] which builds a stylized button representing a single action.
class ActionWidget extends StatelessWidget {
  const ActionWidget({
    super.key,
    this.text,
    this.onPressed,
    this.trailing,
  });

  /// Text to display in this [ActionWidget].
  final String? text;

  /// Trailing to display in this [ActionWidget].
  final Widget? trailing;

  /// Callback, called when this [ActionWidget] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Dense(
        FieldButton(
          onPressed: onPressed,
          text: text ?? '',
          style: TextStyle(color: style.colors.primary),
          trailing: trailing != null
              ? Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(scale: 1.15, child: trailing),
                )
              : null,
        ),
      ),
    );
  }
}

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
import '/ui/page/home/widget/field_button.dart';
import '/ui/widget/outlined_rounded_button.dart';

/// Primary styled [OutlinedRoundedButton].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    this.title = '',
    this.style,
    this.onPressed,
    this.danger = false,
    this.leading,
  });

  /// Text to display.
  final String title;

  /// Callback, called when this button is tapped or activated other way.
  final void Function()? onPressed;

  /// [TextStyle] of the [title] of this [PrimaryButton].
  final TextStyle? style;

  /// Indicator whether this [PrimaryButton] should be displayed in a danger
  /// (destructive) style.
  final bool danger;

  /// [Widget] to display as a leading of this button.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final fieldButton = FieldButton(
      onPressed: onPressed,
      warning: true,
      danger: danger,
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style:
            this.style ??
            (onPressed == null
                ? style.fonts.normal.regular.onBackground.copyWith(
                    color: style.colors.secondaryOpacity87,
                  )
                : style.fonts.normal.regular.onPrimary),
      ),
    );

    if (leading != null) {
      return Stack(
        children: [
          fieldButton,
          Positioned(
            top: 0,
            bottom: 0,
            left: 16,
            child: IgnorePointer(child: leading),
          ),
        ],
      );
    }

    return fieldButton;
  }
}

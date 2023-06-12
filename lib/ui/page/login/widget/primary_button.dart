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
import '/ui/widget/outlined_rounded_button.dart';

/// Primary styled [OutlinedRoundedButton].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    this.title = '',
    this.onPressed,
  });

  /// Text to display.
  final String title;

  /// Callback, called when this button is tapped or activated other way.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return OutlinedRoundedButton(
      maxWidth: double.infinity,
      title: Text(
        title,
        style: TextStyle(
          color: onPressed == null
              ? style.colors.onBackground
              : style.colors.onPrimary,
        ),
      ),
      onPressed: onPressed,
      color: style.colors.primary,
    );
  }
}

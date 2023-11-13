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

/// [OutlinedRoundedButton] with [CustomBoxShadow].
class ShadowedRoundedButton extends StatelessWidget {
  const ShadowedRoundedButton({
    super.key,
    this.child,
    this.color,
    this.onPressed,
  });

  /// Primary content of this button.
  final Widget? child;

  /// Background color of this button.
  final Color? color;

  /// Callback, called when this button is tapped or activated other way.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return OutlinedRoundedButton(
      title: child,
      onPressed: onPressed,
      color: color,
      shadows: [
        CustomBoxShadow(
          blurRadius: 8,
          color: style.colors.onBackgroundOpacity13,
          blurStyle: BlurStyle.outer.workaround,
        ),
      ],
    );
  }
}

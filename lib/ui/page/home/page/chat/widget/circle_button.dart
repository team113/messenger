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
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';

/// Circle button with the provided [icon].
class CircleButton extends StatelessWidget {
  const CircleButton(this.icon, {super.key, this.onPressed});

  /// Icon to display.
  final SvgData icon;

  /// Callback, called when this [CircleButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedButton(
      enabled: onPressed != null,
      onPressed: onPressed,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            CustomBoxShadow(
              blurRadius: 8,
              color: style.colors.onBackgroundOpacity13,
              blurStyle: BlurStyle.outer.workaround,
            ),
          ],
        ),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: style.cardColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Transform.scale(scale: 0.75, child: SvgIcon(icon)),
          ),
        ),
      ),
    );
  }
}

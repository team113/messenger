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
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// Circular close button.
class CloseButton extends StatelessWidget {
  const CloseButton({super.key, this.icon, this.onPressed});

  /// [SvgData] to use inside this button.
  final SvgData? icon;

  /// Callback, called when this button is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return WidgetButton(
      onPressed: onPressed,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.fromLTRB(3, 3, 3, 3),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style.cardColor,
            boxShadow: [
              CustomBoxShadow(
                color: style.colors.onBackgroundOpacity20,
                blurRadius: 2,
                blurStyle: BlurStyle.outer,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: SvgIcon(icon ?? SvgIcons.attachmentClose),
        ),
      ),
    );
  }
}

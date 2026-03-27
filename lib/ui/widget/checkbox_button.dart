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
import 'svg/svg.dart';
import 'widget_button.dart';

/// [SvgIcons.sentWhite] button toggling [value] on and off.
class RowCheckboxButton extends StatelessWidget {
  const RowCheckboxButton({
    super.key,
    this.value = false,
    this.onPressed,
    required this.label,
  });

  /// Current value of this button.
  final bool value;

  /// Callback, called when this button is pressed.
  final void Function(bool s)? onPressed;

  /// Label to display.
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return WidgetButton(
      onPressed: () => onPressed?.call(!value),
      child: Row(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 200),

            decoration: BoxDecoration(
              color: value ? style.colors.primary : style.colors.onPrimary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: style.colors.primary, width: 1),
            ),
            width: 24,
            height: 24,
            child: value ? Center(child: SvgIcon(SvgIcons.sentWhite)) : null,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(label, style: style.fonts.normal.regular.onBackground),
          ),
        ],
      ),
    );
  }
}

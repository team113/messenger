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
import '/ui/widget/svg/svgs.dart';
import '/ui/widget/widget_button.dart';

/// Rectangular small button with a [SvgIcon] in center.
class QuickButton extends StatelessWidget {
  const QuickButton(this.data, {super.key, this.onPressed});

  /// [SvgData] to display the [SvgIcon] with.
  final SvgData data;

  /// Callback, called when this [QuickButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return WidgetButton(
      onPressed: onPressed,
      child: Container(
        width: 54,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: style.colors.primary, width: 0.5),
        ),
        child: Center(child: SvgIcon(data)),
      ),
    );
  }
}

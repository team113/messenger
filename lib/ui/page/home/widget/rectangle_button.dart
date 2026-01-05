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
import '/ui/page/home/widget/avatar.dart';

/// Rectangular filled selectable button.
class RectangleButton extends StatelessWidget {
  const RectangleButton({
    super.key,
    this.selected = false,
    this.onPressed,
    this.label,
    this.child,
  });

  /// Label of this [RectangleButton].
  final String? label;

  /// [Widget] to display inside this [RectangleButton] instead of the [label].
  final Widget? child;

  /// Indicator whether this [RectangleButton] is selected, meaning an
  /// [Icons.check] should be displayed in a trailing.
  final bool selected;

  /// Callback, called when this [RectangleButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Material(
      borderRadius: BorderRadius.circular(10),
      color: selected
          ? style.colors.primary
          : style.colors.onPrimary.darken(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: selected ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DefaultTextStyle(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: selected
                ? style.fonts.normal.regular.onPrimary
                : style.fonts.normal.regular.onBackground,
            child: child ?? Text(label ?? ''),
          ),
        ),
      ),
    );
  }
}

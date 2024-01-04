// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/selected_dot.dart';

/// Rectangular filled selectable button.
class RectangleButton extends StatelessWidget {
  const RectangleButton({
    super.key,
    this.selected = false,
    this.onPressed,
    required this.label,
    this.trailingColor,
    this.radio = false,
    this.toggleable = false,
  });

  /// Label of this [RectangleButton].
  final String label;

  /// Indicator whether this [RectangleButton] is selected, meaning an
  /// [Icons.check] should be displayed in a trailing.
  final bool selected;

  /// Indicator whether this [RectangleButton] is radio button.
  final bool radio;

  /// Callback, called when this [RectangleButton] is pressed.
  final void Function()? onPressed;

  /// [Color] of the trailing background, when [selected] is `true`.
  final Color? trailingColor;

  /// Indicator whether [onPressed] can be invoked when [selected].
  final bool toggleable;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Material(
      borderRadius: BorderRadius.circular(10),
      color: selected && !radio
          ? style.colors.primary
          : style.colors.onPrimary.darken(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: selected && !toggleable ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: selected && !radio
                      ? style.fonts.normal.regular.onPrimary
                      : style.fonts.normal.regular.onBackground,
                ),
              ),
              const SizedBox(width: 12),
              if (trailingColor == null)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: SafeAnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: selected
                        ? CircleAvatar(
                            backgroundColor: radio
                                ? style.colors.primary
                                : style.colors.onPrimary,
                            radius: 12,
                            child: Icon(
                              Icons.check,
                              color: radio
                                  ? style.colors.onPrimary
                                  : style.colors.primary,
                              size: 12,
                            ),
                          )
                        : radio
                            ? const SelectedDot()
                            : const SizedBox(),
                  ),
                )
              else
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircleAvatar(
                    backgroundColor: trailingColor,
                    radius: 12,
                    child: SafeAnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: selected
                          ? Icon(
                              Icons.check,
                              color: style.colors.onPrimary,
                              size: 12,
                            )
                          : const SizedBox(key: Key('None')),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

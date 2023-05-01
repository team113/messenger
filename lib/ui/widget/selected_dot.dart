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

import '/ui/page/home/widget/avatar.dart';

/// Animated [CircleAvatar] representing a selection circle.
class SelectedDot extends StatelessWidget {
  const SelectedDot({
    super.key,
    this.selected = false,
    this.size = 24,
    this.darken = 0,
    this.inverted = true,
    this.outlined = false,
  });

  /// Indicator whether this [SelectedDot] is selected.
  final bool selected;

  /// Diameter of this [SelectedDot].
  final double size;

  /// Amount of darkening to apply to the background of this [SelectedDot].
  final double darken;

  /// Indicator whether this [SelectedDot] should have inverted color relative
  /// to its base one when [selected] is `true`.
  final bool inverted;

  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 30,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected
            ? CircleAvatar(
                key: const Key('Selected'),
                backgroundColor:
                    inverted ? colors.onSecondary : colors.secondary,
                radius: size / 2,
                child: Icon(
                  Icons.check,
                  color: inverted ? colors.secondary : colors.onSecondary,
                  size: 14,
                ),
              )
            : Container(
                key: const Key('Unselected'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: outlined
                        ? Theme.of(context).colorScheme.secondary
                        : const Color(0xFFD7D7D7).darken(darken),
                    width: 1.5,
                  ),
                ),
                width: size,
                height: size,
                child: outlined
                    ? Center(
                        child: Icon(
                          Icons.check,
                          color: colors.secondary,
                          size: 14,
                        ),
                      )
                    : null,
              ),
      ),
    );
  }
}

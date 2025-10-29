// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'animated_switcher.dart';

/// Size of this [SelectedDot].
enum SelectedDotSize { normal, big }

/// Animated [CircleAvatar] representing a selection circle.
class SelectedDot extends StatelessWidget {
  const SelectedDot({
    super.key,
    this.selected = false,
    this.size = SelectedDotSize.normal,
    this.inverted = false,
  });

  /// Indicator whether this [SelectedDot] is selected.
  final bool selected;

  /// Size of this [SelectedDot].
  final SelectedDotSize size;

  /// Indicator whether this [SelectedDot] should have inverted color relative
  /// to its base one.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final double containerSize = switch (size) {
      SelectedDotSize.normal => 20.0,
      SelectedDotSize.big => 25.0,
    };

    final double borderWidth = switch (size) {
      SelectedDotSize.normal => 1.5,
      SelectedDotSize.big => 0.5,
    };

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: SafeAnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected
            ? DecoratedBox(
                key: const Key('Selected'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: inverted
                        ? style.colors.onPrimary
                        : style.colors.primary,
                    width: borderWidth,
                  ),
                  color: inverted
                      ? style.colors.primary
                      : style.colors.onPrimary,
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    color: inverted
                        ? style.colors.onPrimary
                        : style.colors.primary,
                    size: switch (size) {
                      SelectedDotSize.normal => 10,
                      SelectedDotSize.big => 14,
                    },
                  ),
                ),
              )
            : Container(
                key: const Key('Unselected'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: style.colors.secondaryHighlightDarkest,
                    width: borderWidth,
                  ),
                  color: inverted
                      ? style.colors.secondaryHighlight
                      : style.colors.onPrimary,
                ),
              ),
      ),
    );
  }
}

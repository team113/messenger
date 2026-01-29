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
import 'animated_switcher.dart';

/// Size of a [SelectedDot].
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

    final Widget dot;

    if (selected) {
      dot = _DotContainer(
        key: const Key('Selected'),
        size: size,
        border: inverted ? style.colors.onPrimary : style.colors.primary,
        background: inverted ? style.colors.primary : style.colors.onPrimary,
        child: Center(
          child: Icon(
            Icons.check,
            color: inverted ? style.colors.onPrimary : style.colors.primary,
            size: switch (size) {
              SelectedDotSize.normal => 10,
              SelectedDotSize.big => 14,
            },
          ),
        ),
      );
    } else {
      dot = _DotContainer(
        key: const Key('Unselected'),
        size: size,
        border: style.colors.secondaryHighlightDarkest,
        background: inverted
            ? style.colors.secondaryHighlight
            : style.colors.onPrimary,
      );
    }

    return SafeAnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: dot,
    );
  }
}

/// [Container] representing a selection circle.
class _DotContainer extends StatelessWidget {
  const _DotContainer({
    super.key,
    required this.size,
    required this.background,
    required this.border,
    this.child,
  });

  /// Size of this [SelectedDot].
  final SelectedDotSize size;

  /// Background [Color] of this [SelectedDot].
  final Color background;

  /// Border [Color] of this [SelectedDot].
  final Color border;

  /// Widget to be placed in the center of this [SelectedDot].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double dimension = switch (size) {
      SelectedDotSize.normal => 20.0,
      SelectedDotSize.big => 25.0,
    };

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: border,
          width: switch (size) {
            SelectedDotSize.normal => 1.5,
            SelectedDotSize.big => 0.5,
          },
        ),
        color: background,
      ),
      child: child,
    );
  }
}

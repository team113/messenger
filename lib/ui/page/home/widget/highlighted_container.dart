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

/// [AnimatedContainer] highlighting its [child].
class HighlightedContainer extends StatelessWidget {
  const HighlightedContainer({
    super.key,
    this.highlight = false,
    required this.child,
    this.padding,
  });

  /// Indicator whether the [child] should be highlighted.
  final bool highlight;

  /// [Widget] to animate to.
  final Widget child;

  /// Padding of this [AnimatedContainer].
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      curve: Curves.ease,
      color: highlight
          ? style.colors.primaryOpacity20
          : style.colors.primaryOpacity20.withValues(alpha: 0),
      padding: padding,
      child: child,
    );
  }
}

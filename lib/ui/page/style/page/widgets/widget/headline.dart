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

import '/ui/page/home/widget/block.dart';

/// Custom [Block] with the [headline] and [subtitle].
class Headline extends StatelessWidget {
  const Headline({
    super.key,
    this.headline,
    required this.child,
    this.subtitle,
    this.color,
    this.invertHeadline = false,
    this.padding = const EdgeInsets.fromLTRB(32, 16, 32, 16),
    this.top = true,
    this.bottom = true,
  });

  /// [Widget]s to display.
  final Widget child;

  /// Optional header of this [Headline].
  final String? headline;

  /// Indicator whether the [headline] color should be inverted.
  final bool invertHeadline;

  /// Optional subtitle of this [Headline].
  final Widget? subtitle;

  /// Optional background [Color] of this [Block].
  final Color? color;

  /// Padding to apply to the [child].
  final EdgeInsets padding;

  /// Indicator whether this [Headline] should have additional top margin.
  final bool top;

  /// Indicator whether this [Headline] should have additional bottom margin.
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return Block(
      color: color,
      headline: headline ?? child.runtimeType.toString(),
      invertHeadline: invertHeadline,
      topMargin: top ? 32 : null,
      maxWidth: 450,
      padding: padding,
      children: [
        if (top) const SizedBox(height: 16),
        SelectionContainer.disabled(child: child),
        if (bottom || subtitle != null) ...[
          const SizedBox(height: 8),
          if (subtitle != null) SelectionContainer.disabled(child: subtitle!),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

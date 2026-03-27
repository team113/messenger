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

import '/ui/page/home/widget/block.dart';

/// Custom [Block] with the [headline] and [subtitle].
class Headline extends StatelessWidget {
  const Headline({
    super.key,
    this.headline,
    required this.child,
    this.subtitle,
    this.background,
    this.padding = Block.defaultPadding,
    this.top = true,
    this.bottom = true,
  });

  /// [Widget]s to display.
  final Widget child;

  /// Optional header of this [Headline].
  final String? headline;

  /// Optional subtitle of this [Headline].
  final Widget? subtitle;

  /// Optional background [Color] of this [Block].
  final Color? background;

  /// Padding to apply to the [child].
  final EdgeInsets padding;

  /// Indicator whether this [Headline] should have additional top margin.
  final bool top;

  /// Indicator whether this [Headline] should have additional bottom padding.
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return Block(
      background: background,
      headline: headline ?? child.runtimeType.toString(),
      margin: top ? Block.defaultMargin.copyWith(top: 32) : Block.defaultMargin,
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

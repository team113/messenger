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
import '/ui/page/home/page/chat/widget/selection_text.dart';

/// [Text] centered within a line.
class LineDivider extends StatelessWidget {
  const LineDivider(
    String this.label, {
    super.key,
    this.primary = false,
    this.bold = false,
  }) : span = null,
       selectable = false;

  /// Builds a [LineDivider] with the [TextSpan] in the center.
  const LineDivider.rich(
    TextSpan this.span, {
    super.key,
    this.primary = false,
    this.bold = false,
  }) : label = null,
       selectable = false;

  /// Builds a [LineDivider] with the [SelectionText] in the center.
  const LineDivider.selectable(
    TextSpan this.span, {
    super.key,
    this.primary = false,
    this.bold = false,
  }) : label = null,
       selectable = true;

  /// Label to put in the centered [Text].
  final String? label;

  /// [TextSpan] to put in the centered [Text].
  final TextSpan? span;

  /// Indicator whether [label] should have a primary style.
  final bool primary;

  /// Indicator whether this [LineDivider] should be opaque.
  final bool bold;

  /// Indicator whether the [TextSpan] used should use [SelectionText] instead
  /// of [Text.rich].
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Row(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            height: 0.5,
            color: bold
                ? style.colors.onBackground
                : style.colors.onBackgroundOpacity27,
          ),
        ),
        if (label?.isNotEmpty == true) ...[
          const SizedBox(width: 8),
          Text(
            label!,
            style: bold
                ? style.fonts.small.regular.onBackground
                : primary
                ? style.fonts.small.regular.primary
                : style.fonts.small.regular.secondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(width: 8),
        ],
        if (span != null) ...[
          const SizedBox(width: 8),
          if (selectable)
            SelectionArea(
              child: SelectionText.rich(
                span!,
                style: primary
                    ? style.fonts.small.regular.primary
                    : style.fonts.small.regular.secondary,
              ),
            )
          else
            Text.rich(
              span!,
              style: primary
                  ? style.fonts.small.regular.primary
                  : style.fonts.small.regular.secondary,
              textAlign: TextAlign.center,
            ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Container(
            width: double.infinity,
            height: 0.5,
            color: bold
                ? style.colors.onBackground
                : style.colors.onBackgroundOpacity27,
          ),
        ),
      ],
    );
  }
}

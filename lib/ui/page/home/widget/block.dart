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

import '/themes.dart';
import '/util/platform_utils.dart';
import 'highlighted_container.dart';

/// Stylized grouped section of the provided [children].
class Block extends StatelessWidget {
  const Block({
    super.key,
    this.title,
    this.highlight = false,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.expanded,
    this.padding = const EdgeInsets.fromLTRB(32, 16, 32, 16),
    this.children = const [],
  });

  /// Optional header of this [Block].
  final String? title;

  /// Indicator whether this [Block] should be highlighted.
  final bool highlight;

  /// [CrossAxisAlignment] to apply to the [children].
  final CrossAxisAlignment crossAxisAlignment;

  /// Indicator whether this [Block] should occupy the whole space, if `true`,
  /// or be fixed width otherwise.
  ///
  /// If not specified, then [MobileExtensionOnContext.isNarrow] is used.
  final bool? expanded;

  /// Padding to apply to the [children].
  final EdgeInsets padding;

  /// [Widget]s to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return HighlightedContainer(
      highlight: highlight == true,
      child: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          decoration: BoxDecoration(
            border: style.primaryBorder,
            color: style.messageColor,
            borderRadius: BorderRadius.circular(15),
          ),
          constraints: (expanded ?? context.isNarrow)
              ? null
              : const BoxConstraints(maxWidth: 400),
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: crossAxisAlignment,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      child: Text(
                        title!,
                        style: style.fonts.big.regular.onBackground,
                      ),
                    ),
                  ),
                ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

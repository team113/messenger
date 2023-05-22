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

/// Stylized grouped section of the provided [children].
class Block extends StatelessWidget {
  const Block({
    super.key,
    this.children = const [],
    this.title,
    this.padding = const EdgeInsets.fromLTRB(32, 16, 32, 16),
  });

  /// Optional header of this [Block].
  final String? title;

  /// [Widget]s to display.
  final List<Widget> children;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          border: style.primaryBorder,
          color: style.messageColor,
          borderRadius: BorderRadius.circular(15),
        ),
        constraints:
            context.isNarrow ? null : const BoxConstraints(maxWidth: 400),
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: style.systemMessageStyle.copyWith(
                        color: style.colors.onBackground,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

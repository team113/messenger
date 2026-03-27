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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/page/home/widget/block.dart';

/// Custom [Block] with the headlines.
class Headlines extends StatelessWidget {
  const Headlines({super.key, required this.children, this.color});

  /// [Widget]s to display.
  final List<({String headline, Widget widget})> children;

  /// Optional background [Color] of this [Headlines].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Block(
      padding: EdgeInsets.zero,
      background: color,
      margin: Block.defaultMargin.copyWith(top: 32),
      maxWidth: 450,
      children: [
        ...children.mapIndexed((i, e) {
          return [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                e.headline,
                style: style.fonts.small.regular.secondaryHighlightDarkest,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SelectionContainer.disabled(child: e.widget),
            ),
            if (i != children.length - 1) const SizedBox(height: 32),
          ];
        }).flattened,
        const SizedBox(height: 16),
      ],
    );
  }
}

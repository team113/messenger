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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/family.dart';
import 'widget/row.dart';

/// View of the [StyleTab.typography] page.
class TypographyView extends StatelessWidget {
  const TypographyView({super.key, this.inverted = false, this.dense = false});

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  /// Indicator whether this view should be compact, meaning minimal [Padding]s.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final List<(FontWeight, String, String)> families = [
      (FontWeight.w400, 'Roboto (Regular)', 'Roboto-Regular.ttf'),
      (FontWeight.w700, 'Roboto (Bold)', 'Roboto-Bold.ttf'),
    ];

    return ScrollableColumn(
      children: [
        SizedBox(height: CustomAppBar.height),
        Block(
          title: 'Font families',
          expanded: true,
          children: families
              .map((e) => FontFamily(weight: e.$1, name: e.$2, asset: e.$3))
              .toList(),
        ),
        ...style.fonts.schema.entries.map((size) {
          return Block(
            title:
                '${size.key.capitalized} (${size.value.values.first.values.first.fontSize} pt)',
            expanded: true,
            children: size.value.entries
                .map((weight) {
                  return weight.value.entries.map((color) {
                    return FontRow(
                      font: color.value,
                      size: size.key,
                      weight: weight.key,
                      color: color.key,
                    );
                  });
                })
                .expand((e) => e)
                .toList(),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

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
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/color_schema.dart';

/// View of the [StyleTab.colors] page.
class ColorsView extends StatelessWidget {
  const ColorsView({super.key, this.inverted = false});

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final List<(Color, String)> colors = [
      (style.colors.onBackground, 'onBackground'),
      (style.colors.secondaryBackground, 'secondaryBackground'),
      (style.colors.secondaryBackgroundLight, 'secondaryBackgroundLight'),
      (style.colors.secondaryBackgroundLightest, 'secondaryBackgroundLightest'),
      (style.colors.secondary, 'secondary'),
      (style.colors.secondaryHighlightDarkest, 'secondaryHighlightDarkest'),
      (style.colors.secondaryHighlightDark, 'secondaryHighlightDark'),
      (style.colors.secondaryHighlight, 'secondaryHighlight'),
      (style.colors.background, 'background'),
      (style.colors.secondaryOpacity87, 'secondaryOpacity87'),
      (style.colors.onBackgroundOpacity50, 'onBackgroundOpacity50'),
      (style.colors.onBackgroundOpacity40, 'onBackgroundOpacity40'),
      (style.colors.onBackgroundOpacity27, 'onBackgroundOpacity27'),
      (style.colors.onBackgroundOpacity20, 'onBackgroundOpacity20'),
      (style.colors.onBackgroundOpacity13, 'onBackgroundOpacity13'),
      (style.colors.onBackgroundOpacity7, 'onBackgroundOpacity7'),
      (style.colors.onBackgroundOpacity2, 'onBackgroundOpacity2'),
      (style.colors.onPrimary, 'onPrimary'),
      (style.colors.onPrimaryOpacity95, 'onPrimaryOpacity95'),
      (style.colors.onPrimaryOpacity50, 'onPrimaryOpacity50'),
      (style.colors.onPrimaryOpacity25, 'onPrimaryOpacity25'),
      (style.colors.onPrimaryOpacity7, 'onPrimaryOpacity7'),
      (style.colors.backgroundAuxiliary, 'backgroundAuxiliary'),
      (style.colors.backgroundAuxiliaryLight, 'backgroundAuxiliaryLight'),
      (style.colors.onSecondaryOpacity88, 'onSecondaryOpacity88'),
      (style.colors.onSecondary, 'onSecondary'),
      (style.colors.onSecondaryOpacity60, 'onSecondaryOpacity60'),
      (style.colors.onSecondaryOpacity50, 'onSecondaryOpacity50'),
      (style.colors.onSecondaryOpacity20, 'onSecondaryOpacity20'),
      (style.colors.primaryHighlight, 'primaryHighlight'),
      (style.colors.primary, 'primary'),
      (style.colors.primaryHighlightShiniest, 'primaryHighlightShiniest'),
      (style.colors.primaryHighlightLightest, 'primaryHighlightLightest'),
      (style.colors.primaryLight, 'primaryLight'),
      (style.colors.primaryLightest, 'primaryLightest'),
      (style.colors.backgroundAuxiliaryLighter, 'backgroundAuxiliaryLighter'),
      (style.colors.backgroundAuxiliaryLightest, 'backgroundAuxiliaryLightest'),
      (style.colors.accept, 'accept'),
      (style.colors.acceptAuxiliary, 'acceptAuxiliary'),
      (style.colors.acceptLight, 'acceptLight'),
      (style.colors.acceptLighter, 'acceptLighter'),
      (style.colors.acceptLightest, 'acceptLightest'),
      (style.colors.danger, 'danger'),
      (style.colors.decline, 'decline'),
      (style.colors.declineOpacity88, 'declineOpacity88'),
      (style.colors.declineOpacity50, 'declineOpacity50'),
      (style.colors.warning, 'warning'),
    ];

    final Iterable<(Color, String?)> avatars = style.colors.userColors
        .mapIndexed((i, color) => (color, 'userColors[$i]'))
        .toList();

    return ScrollableColumn(
      children: [
        SizedBox(height: CustomAppBar.height),
        Block(
          title: 'Colors',
          expanded: true,
          padding: const EdgeInsets.only(top: 16),
          children: [
            ColorSchemaWidget(colors, inverted: inverted),
            const SizedBox(height: 16),
          ],
        ),
        Block(
          title: 'Avatars',
          expanded: true,
          padding: const EdgeInsets.only(top: 16),
          children: [
            ColorSchemaWidget(avatars, inverted: inverted),
            const SizedBox(height: 16),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

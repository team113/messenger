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
import '/ui/page/style/widget/builder_wrap.dart';
import '/ui/page/style/widget/header.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/family.dart';
import 'widget/font.dart';
import 'widget/style.dart';

/// View of the [StyleTab.typography] page.
class TypographyView extends StatelessWidget {
  const TypographyView({
    super.key,
    this.inverted = false,
    this.dense = false,
  });

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  /// Indicator whether this view should be compact, meaning minimal [Padding]s.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final Iterable<(TextStyle, String)> styles = [
      (style.fonts.displayBold, 'displayBold'),
      (style.fonts.displayLarge, 'displayLarge'),
      (style.fonts.displayMedium, 'displayMedium'),
      (style.fonts.displaySmall, 'displaySmall'),
      (style.fonts.displayTiny, 'displayTiny'),
      (style.fonts.headlineLarge, 'headlineLarge'),
      (style.fonts.headlineMedium, 'headlineMedium'),
      (style.fonts.headlineSmall, 'headlineSmall'),
      (style.fonts.titleLarge, 'titleLarge'),
      (style.fonts.titleMedium, 'titleMedium'),
      (style.fonts.titleSmall, 'titleSmall'),
      (style.fonts.labelLarge, 'labelLarge'),
      (style.fonts.labelMedium, 'labelMedium'),
      (style.fonts.labelSmall, 'labelSmall'),
      (style.fonts.bodyLarge, 'bodyLarge'),
      (style.fonts.bodyMedium, 'bodyMedium'),
      (style.fonts.bodySmall, 'bodySmall'),
      (style.fonts.bodyTiny, 'bodyTiny'),
    ];

    final Iterable<(TextStyle, String)> fonts = [
      (style.fonts.displayBold, 'displayBold'),
      (style.fonts.displayBoldOnPrimary, 'displayBoldOnPrimary'),
      (style.fonts.displayLarge, 'displayLarge'),
      (style.fonts.displayLargeOnPrimary, 'displayLargeOnPrimary'),
      (style.fonts.displayLargeSecondary, 'displayLargeSecondary'),
      (style.fonts.displayMedium, 'displayMedium'),
      (style.fonts.displayMediumSecondary, 'displayMediumSecondary'),
      (style.fonts.displaySmall, 'displaySmall'),
      (style.fonts.displaySmallSecondary, 'displaySmallSecondary'),
      (style.fonts.displayTiny, 'displayTiny'),
      (style.fonts.displayTinyOnPrimary, 'displayTinyOnPrimary'),
      (style.fonts.displayTinySecondary, 'displayTinySecondary'),
      (style.fonts.headlineLarge, 'headlineLarge'),
      (style.fonts.headlineLargeOnPrimary, 'headlineLarge'),
      (style.fonts.headlineMedium, 'headlineMedium'),
      (style.fonts.headlineMediumOnPrimary, 'headlineMedium'),
      (style.fonts.headlineSmall, 'headlineSmall'),
      (style.fonts.headlineSmallOnPrimary, 'headlineSmallOnPrimary'),
      (
        style.fonts.headlineSmallOnPrimary.copyWith(
          shadows: [
            Shadow(blurRadius: 6, color: style.colors.onBackground),
            Shadow(blurRadius: 6, color: style.colors.onBackground),
          ],
        ),
        'headlineSmallOnPrimary (shadows)',
      ),
      (style.fonts.headlineSmallSecondary, 'headlineSmall'),
      (style.fonts.titleLarge, 'titleLarge'),
      (style.fonts.titleLargePrimary, 'titleLargePrimary'),
      (style.fonts.titleLargeOnPrimary, 'titleLargeOnPrimary'),
      (style.fonts.titleLargeSecondary, 'titleLargeSecondary'),
      (style.fonts.titleMedium, 'titleMedium'),
      (style.fonts.titleMediumDanger, 'titleMediumDanger'),
      (style.fonts.titleMediumOnPrimary, 'titleMediumOnPrimary'),
      (style.fonts.titleMediumPrimary, 'titleMediumPrimary'),
      (style.fonts.titleMediumSecondary, 'titleMediumSecondary'),
      (style.fonts.titleSmall, 'titleSmall'),
      (style.fonts.titleSmallOnPrimary, 'titleSmallOnPrimary'),
      (style.fonts.labelLarge, 'labelLarge'),
      (style.fonts.labelLargeOnPrimary, 'labelLargeOnPrimary'),
      (style.fonts.labelLargePrimary, 'labelLargePrimary'),
      (style.fonts.labelLargeSecondary, 'labelLargeSecondary'),
      (style.fonts.labelMedium, 'labelMedium'),
      (style.fonts.labelMediumOnPrimary, 'labelMediumOnPrimary'),
      (style.fonts.labelMediumPrimary, 'labelMediumPrimary'),
      (style.fonts.labelMediumSecondary, 'labelMediumSecondary'),
      (style.fonts.labelSmall, 'labelSmall'),
      (style.fonts.labelSmallOnPrimary, 'labelSmallOnPrimary'),
      (style.fonts.labelSmallPrimary, 'labelSmallPrimary'),
      (style.fonts.labelSmallSecondary, 'labelSmallSecondary'),
      (style.fonts.bodyLarge, 'bodyLarge'),
      (style.fonts.bodyLargePrimary, 'bodyLargePrimary'),
      (style.fonts.bodyLargeSecondary, 'bodyLargeSecondary'),
      (style.fonts.bodyMedium, 'bodyMedium'),
      (style.fonts.bodyMediumOnPrimary, 'bodyMediumOnPrimary'),
      (style.fonts.bodyMediumPrimary, 'bodyMediumPrimary'),
      (style.fonts.bodyMediumSecondary, 'bodyMediumSecondary'),
      (style.fonts.bodySmall, 'bodySmall'),
      (style.fonts.bodySmallOnPrimary, 'bodySmallOnPrimary'),
      (style.fonts.bodySmallPrimary, 'bodySmallPrimary'),
      (style.fonts.bodySmallSecondary, 'bodySmallSecondary'),
      (style.fonts.bodyTiny, 'bodyTiny'),
      (style.fonts.bodyTinyOnPrimary, 'bodyTinyOnPrimary'),
    ];

    final List<(FontWeight, String)> families = [
      (FontWeight.w300, 'SFUI-Light'),
      (FontWeight.w400, 'SFUI-Regular'),
      (FontWeight.w700, 'SFUI-Bold'),
    ];

    return ScrollableColumn(
      children: [
        const SizedBox(height: 16),
        const Header('Typography'),
        const SubHeader('Fonts'),
        BuilderWrap(
          fonts,
          inverted: inverted,
          dense: dense,
          (e) => FontWidget(e, inverted: inverted, dense: dense),
        ),
        const SubHeader('Typefaces'),
        BuilderWrap(
          styles,
          inverted: inverted,
          dense: dense,
          (e) => FontWidget((
            e.$1.copyWith(
              color:
                  inverted ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
            ),
            e.$2,
          ), inverted: inverted, dense: dense),
        ),
        const SubHeader('Families'),
        BuilderWrap(
          families,
          inverted: inverted,
          dense: dense,
          (e) => FontFamily(e, inverted: inverted, dense: dense),
        ),
        const SubHeader('Styles'),
        BuilderWrap(
          styles,
          inverted: inverted,
          dense: dense,
          (e) => FontStyleWidget(e, inverted: inverted),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

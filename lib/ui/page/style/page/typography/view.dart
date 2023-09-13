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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';

import '/themes.dart';
import '/ui/page/style/widget/builder_wrap.dart';
import '/ui/page/style/widget/header.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/family.dart';
import 'widget/font.dart';
import 'widget/style.dart';

/// View of the [StyleTab.typography] page.
class TypographyView extends StatefulWidget {
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
  State<TypographyView> createState() => _TypographyViewState();
}

class _TypographyViewState extends State<TypographyView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final Iterable<(TextStyle, String)> styles = [
      (style.fonts.displayLarge, 'displayLarge'),
      (style.fonts.displayMedium, 'displayMedium'),
      (style.fonts.displaySmall, 'displaySmall'),
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
    ];

    Iterable<(TextStyle, String)> fonts = [
      (style.fonts.displayLarge, 'displayLarge'),
      (style.fonts.displayLargeOnPrimary, 'displayLargeOnPrimary'),
      (style.fonts.displayMedium, 'displayMedium'),
      (style.fonts.displayMediumSecondary, 'displayMediumSecondary'),
      (style.fonts.displaySmall, 'displaySmall'),
      (style.fonts.displaySmallOnPrimary, 'displaySmallOnPrimary'),
      (style.fonts.displaySmallSecondary, 'displaySmallSecondary'),
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
      (style.fonts.titleLargeOnPrimary, 'titleLarge'),
      (style.fonts.titleLargeSecondary, 'titleLarge'),
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
    ];

    fonts = fonts.sorted(
      (a, b) => b.$1.fontSize?.compareTo(a.$1.fontSize ?? 0) ?? 0,
    );

    final List<(FontWeight, String)> families = [
      (FontWeight.w300, 'SFUI-Light'),
      (FontWeight.w400, 'SFUI-Regular'),
      (FontWeight.w700, 'SFUI-Bold'),
    ];

    return SafeScrollbar(
      controller: _scrollController,
      margin: const EdgeInsets.only(top: CustomAppBar.height - 10),
      child: ScrollableColumn(
        controller: _scrollController,
        children: [
          const SizedBox(height: 16 + 5),
          const Header('Typography'),
          const SubHeader('Families'),
          BuilderWrap(
            families,
            inverted: widget.inverted,
            dense: widget.dense,
            (e) =>
                FontFamily(e, inverted: widget.inverted, dense: widget.dense),
          ),
          const SubHeader('Fonts'),
          BuilderWrap(
            fonts,
            inverted: widget.inverted,
            dense: widget.dense,
            (e) =>
                FontWidget(e, inverted: widget.inverted, dense: widget.dense),
          ),
          // const SubHeader('Typefaces'),
          // BuilderWrap(
          //   styles,
          //   inverted: widget.inverted,
          //   dense: widget.dense,
          //   (e) => FontWidget(
          //     (
          //       e.$1.copyWith(
          //         color: widget.inverted
          //             ? const Color(0xFFFFFFFF)
          //             : const Color(0xFF000000),
          //       ),
          //       e.$2,
          //     ),
          //     inverted: widget.inverted,
          //     dense: widget.dense,
          //   ),
          // ),
          const SubHeader('Styles'),
          BuilderWrap(
            styles,
            inverted: widget.inverted,
            dense: widget.dense,
            (e) => FontStyleWidget(e, inverted: widget.inverted),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

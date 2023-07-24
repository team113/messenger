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

import '../../widget/header.dart';
import '/themes.dart';
import '/ui/page/style/widget/builder_wrap.dart';
import 'widget/family.dart';
import 'widget/font.dart';
import 'widget/style.dart';

/// View of the [StyleTab.typography] page.
class TypographyView extends StatelessWidget {
  const TypographyView(this.inverted, this.compact, {super.key});

  /// Indicator whether this [TypographyView] should have its colors inverted.
  final bool inverted;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    final List<(TextStyle?, String)> styles = [
      (fonts.displayLarge, 'displayLarge'),
      (fonts.displayMedium, 'displayMedium'),
      (fonts.displaySmall, 'displaySmall'),
      (fonts.headlineLarge, 'headlineLarge'),
      (fonts.headlineMedium, 'headlineMedium'),
      (fonts.headlineSmall, 'headlineSmall'),
      (fonts.labelLarge, 'labelLarge'),
      (fonts.labelMedium, 'labelMedium'),
      (fonts.labelSmall, 'labelSmall'),
      (fonts.bodyLarge, 'bodyLarge'),
      (fonts.bodyMedium, 'bodyMedium'),
      (fonts.bodySmall, 'bodySmall'),
    ];

    final List<(FontWeight?, String)> families = [
      (FontWeight.w300, 'SFUI-Light'),
      (FontWeight.w400, 'SFUI-Regular'),
      (FontWeight.w700, 'SFUI-Bold'),
    ];

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate(
            [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 0 : 16,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    const Header(label: 'Typography'),
                    const SmallHeader(label: 'Font'),
                    BuilderWrap(
                      styles,
                      inverted: inverted,
                      padding: EdgeInsets.zero,
                      (e) => FontWidget(
                        inverted,
                        compact,
                        style: e.$1,
                        title: e.$2,
                      ),
                    ),
                    const SmallHeader(label: 'Font families'),
                    BuilderWrap(
                      families,
                      inverted: inverted,
                      padding: EdgeInsets.zero,
                      (e) =>
                          FontFamily(inverted, fontWeight: e.$1, label: e.$2),
                    ),
                    const SmallHeader(label: 'Styles'),
                    BuilderWrap(
                      styles,
                      inverted: inverted,
                      (e) => FontStyle(inverted, style: e.$1, title: e.$2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

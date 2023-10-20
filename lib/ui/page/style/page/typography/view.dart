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
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/style/widget/builder_wrap.dart';
import '/ui/page/style/widget/header.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/family.dart';
import 'widget/font.dart';

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

    final Iterable<(TextStyle, String)> fonts = [
      ...style.fonts.styles.map((e) => (e, e.runtimeType.toString())),
    ];

    final List<(FontWeight, String)> families = [
      (FontWeight.w300, 'SFUI-Light'),
      (FontWeight.w400, 'SFUI-Regular'),
      (FontWeight.w700, 'SFUI-Bold'),
    ];

    return ScrollableColumn(
      children: [
        const SizedBox(height: CustomAppBar.height),
        const SizedBox(height: 16),
        const Header('Typography'),
        const SubHeader('Fonts'),
        BuilderWrap(
          fonts,
          inverted: inverted,
          dense: dense,
          (e) => FontWidget(e, inverted: inverted, dense: dense),
        ),
        const SubHeader('Families'),
        BuilderWrap(
          families,
          inverted: inverted,
          dense: dense,
          (e) => FontFamily(e, inverted: inverted, dense: dense),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

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

import '/ui/page/style/widget/headers.dart';
import 'widget/family.dart';
import 'widget/font_column.dart';
import 'widget/style.dart';

/// View of the [StyleTab.typography] page.
class FontsView extends StatelessWidget {
  const FontsView(this.inverted, {super.key});

  /// Indicator whether this [FontsView] should have its colors inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Header(label: 'Typography'),
          const SmallHeader(label: 'Font families'),
          FontFamiliesWidget(inverted),
          const Divider(),
          const SmallHeader(label: 'Font'),
          FontColumnWidget(inverted),
          const Divider(),
          const SmallHeader(label: 'Styles'),
          FontStyleWidget(inverted),
          const Divider(),
        ],
      ),
    );
  }
}

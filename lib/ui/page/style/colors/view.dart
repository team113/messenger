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

import '../widget/headers.dart';
import 'widget/avatar.dart';
import 'widget/palette.dart';

/// View of the [StyleTab.colors] page.
class ColorStyleView extends StatelessWidget {
  const ColorStyleView(this.isDarkMode, {super.key});

  /// Indicator whether the dark mode is enabled or not.
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Header(label: 'Colors palette'),
          const SmallHeader(label: 'Application colors'),
          PaletteWidget(isDarkMode),
          const Divider(),
          const SmallHeader(label: 'Avatar colors'),
          AvatarColors(isDarkMode),
          const Divider(),
        ],
      ),
    );
  }
}

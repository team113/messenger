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

import '/ui/page/style/colors/view.dart';
import '/ui/page/style/element/view.dart';
import '/ui/page/style/fonts/view.dart';
import '/ui/page/style/media/view.dart';

class ContentScrollView extends StatelessWidget {
  const ContentScrollView({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 70),
                  child: Column(
                    children: [
                      // ColorStyleView(isDarkMode: isDarkMode),
                      // FontsView(isDarkMode: isDarkMode),
                      // MultimediaView(isDarkMode: isDarkMode),
                      const SizedBox(height: 200),
                      ElementStyleTabView(isDarkMode: isDarkMode),
                      ColorStyleView(isDarkMode: isDarkMode),
                      FontsView(isDarkMode: isDarkMode),
                      MultimediaView(isDarkMode: isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

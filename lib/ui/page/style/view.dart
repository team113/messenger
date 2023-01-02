// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'tab/color.dart';
import 'tab/text.dart';
import 'tab/element.dart';

/// View of the [Routes.style] page.
class StyleView extends StatelessWidget {
  const StyleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const TabBar(
            tabs: [
              Tab(text: 'Шрифты'),
              Tab(text: 'Цвета'),
              Tab(text: 'Графика'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FontStyleTabView(),
            ColorStyleTabView(),
            ElementStyleTabView(),
          ],
        ),
      ),
    );
  }
}

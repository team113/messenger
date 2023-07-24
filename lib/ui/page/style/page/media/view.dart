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

import '/ui/page/style/widget/header.dart';
import 'widget/animation.dart';
import 'widget/images.dart';
import 'widget/sounds.dart';

class MultimediaView extends StatelessWidget {
  const MultimediaView(this.isDarkMode, this.compact, {super.key});

  final bool isDarkMode;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate(
            [
              Padding(
                padding: EdgeInsets.all(compact ? 0 : 20),
                child: Column(
                  children: [
                    const Header(label: 'Multimedia'),
                    const SmallHeader(label: 'Images'),
                    ImagesView(isDarkMode: isDarkMode),
                    const Divider(),
                    const SmallHeader(label: 'Animation'),
                    const AnimationStyleWidget(),
                    const Divider(),
                    const SmallHeader(label: 'Sound'),
                    const SoundsWidget(),
                    const Divider(),
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

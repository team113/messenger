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
// import 'package:messenger/themes.dart';

import '../colors/view.dart';
import '../fonts/family.dart';
import 'widget/avatar.dart';
import 'widget/header.dart';
import 'widget/logo.dart';

// import '/themes.dart';

/// Elements tab view of the [Routes.style] page.
class ElementStyleTabView extends StatelessWidget {
  const ElementStyleTabView({super.key});

  @override
  Widget build(BuildContext context) {
    // final (style, fonts) = Theme.of(context).styles;

    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 70),
      child: Column(
        children: [
          ColorStyleView(),
          Header(label: 'Typography'),
          SmallHeader(label: 'Font'),
          FontFamiliesView(),
          Divider(),
          SmallHeader(label: 'Styles'),
          Divider(),
          SmallHeader(label: 'Intervals'),
          Divider(),
          Header(label: 'Multimedia'),
          SmallHeader(label: 'Images'),
          LogoView(),
          Divider(),
          SmallHeader(label: 'Animation'),
          Divider(),
          SmallHeader(label: 'Sound'),
          Divider(),
          Header(label: 'Elements'),
          SmallHeader(label: 'Text fields'),
          Divider(),
          SmallHeader(label: 'Buttons'),
          Divider(),
          SmallHeader(label: 'Avatars'),
          AvatarView(),
          Divider(),
          SmallHeader(label: 'System messages'),
          Divider(),
          SmallHeader(label: 'Switchers'),
          Divider(),
          SmallHeader(label: 'Pop-ups'),
          Divider(),
        ],
      ),
    );
  }
}

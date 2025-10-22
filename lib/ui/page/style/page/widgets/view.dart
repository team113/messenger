// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/routes.dart';
import 'section/animations.dart';
import 'section/avatars.dart';
import 'section/buttons.dart';
import 'section/call.dart';
import 'section/chat.dart';
import 'section/fields.dart';
import 'section/images.dart';
import 'section/loaders.dart';
import 'section/navigation.dart';
import 'section/sounds.dart';
import 'section/switches.dart';
import 'section/system.dart';
import 'section/tiles.dart';

/// Widgets view of the [Routes.style] page.
class WidgetsView extends StatelessWidget {
  const WidgetsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      cacheExtent: 3000,
      children: [
        ...ImagesSection.build(),
        ...ChatSection.build(context),
        ...AnimationsSection.build(),
        ...AvatarsSection.build(),
        ...FieldsSection.build(context),
        ...ButtonsSection.build(context),
        ...SwitchesSection.build(),
        ...TilesSection.build(context),
        ...SystemSection.build(),
        ...NavigationSection.build(context),
        ...CallSection.build(context),
        ...LoadersSection.build(context),
        ...SoundsSection.build(),
      ],
    );
  }
}

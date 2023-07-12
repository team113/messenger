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
import 'widget/avatar.dart';
import 'widget/button.dart';
import 'widget/navigation.dart';
import 'widget/pop_up.dart';
import 'widget/switcher.dart';
import 'widget/system_message.dart';
import 'widget/text_field.dart';

/// Elements tab view of the [Routes.style] page.
class ElementStyleTabView extends StatelessWidget {
  const ElementStyleTabView({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Header(label: 'Elements'),
        const SmallHeader(label: 'Avatars'),
        AvatarView(isDarkMode: isDarkMode),
        const Divider(),
        const SmallHeader(label: 'Text fields'),
        TextFieldWidget(isDarkMode: isDarkMode),
        const Divider(),
        const SmallHeader(label: 'Buttons'),
        ButtonsWidget(isDarkMode: isDarkMode),
        const Divider(),
        const SmallHeader(label: 'System messages'),
        const SystemMessageWidget(),
        const Divider(),
        const SmallHeader(label: 'Switchers'),
        SwitcherWidget(isDarkMode: isDarkMode),
        const Divider(),
        const SmallHeader(label: 'Pop-ups'),
        const PopUpWidget(),
        const Divider(),
        const SmallHeader(label: 'Navigation'),
        const NavigationWidget(),
        const Divider(),
        const SizedBox(height: 50),
        // const Header(label: 'Elements'),
        // const SmallHeader(label: 'Text fields'),
        // const TextFieldWidget(),
        // const Divider(),
        // const SmallHeader(label: 'Buttons'),
        // ButtonsWidget(isDarkMode: isDarkMode),
        // const Divider(),
        // const SmallHeader(label: 'Avatars'),
        // const AvatarView(),
        // const Divider(),
        // const SmallHeader(label: 'System messages'),
        // const SystemMessageWidget(),
        // const Divider(),
        // const SmallHeader(label: 'Switchers'),
        // const SwitcherWidget(),
        // const Divider(),
        // const SmallHeader(label: 'Pop-ups'),
        // const PopUpWidget(),
        // const Divider(),
        // const SmallHeader(label: 'Navigation'),
        // const NavigationWidget(),
        // const Divider(),
        // const SizedBox(height: 50),
      ],
    );
  }
}

// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/menu/widget/menu_button.dart';

class VacancyWidget extends StatelessWidget {
  const VacancyWidget(
    this.text, {
    super.key,
    this.subtitle = const [],
    this.trailing = const [],
    this.onPressed,
    this.selected = false,
  });

  final String text;
  final List<Widget> subtitle;
  final List<Widget> trailing;
  final void Function()? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MenuButton(
        title: text,
        icon: Icon(
          Icons.work,
          color: selected ? style.colors.onPrimary : style.colors.primary,
        ),
        onPressed: onPressed,
        trailing: trailing,
        inverted: selected,
        children: subtitle,
      ),
    );
  }
}

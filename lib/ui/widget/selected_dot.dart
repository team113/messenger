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

import '/ui/page/home/widget/avatar.dart';

/// Animated [CircleAvatar] representing selection circle.
class SelectedDot extends StatelessWidget {
  const SelectedDot({
    super.key,
    this.selected = false,
    this.size = 24,
    this.darken = 0,
    this.selectedKey,
    this.unSelectedKey,
  });

  /// Indicator whether should display the [CircleAvatar].
  final bool selected;

  /// Size [CircleAvatar] representing selection circle.
  final double size;

  /// Darkening the circle displayed when [SelectedDot] is not selected.
  final double darken;

  /// [Key] for the [CircleAvatar].
  final Key? selectedKey;

  /// [Key] for the empty circle.
  final Key? unSelectedKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected
            ? CircleAvatar(
                key: selectedKey,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                radius: size / 2,
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              )
            : Container(
                key: unSelectedKey,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD7D7D7).darken(darken),
                    width: 1,
                  ),
                ),
                width: size,
                height: size,
              ),
      ),
    );
  }
}

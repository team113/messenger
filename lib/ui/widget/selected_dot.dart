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
import 'package:messenger/themes.dart';

import '/ui/page/home/widget/avatar.dart';

/// Animated [CircleAvatar] representing a selection circle.
class SelectedDot extends StatelessWidget {
  const SelectedDot({
    super.key,
    this.selected = false,
    this.size = 24,
    this.darken = 0,
  });

  /// Indicator whether this [SelectedDot] is selected.
  final bool selected;

  /// Diameter of this [SelectedDot].
  final double size;

  /// Amount of darkening to apply to the background of this [SelectedDot].
  final double darken;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<Style>()!;
    return SizedBox(
      width: 30,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected
            ? CircleAvatar(
                key: const Key('Selected'),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                radius: size / 2,
                child: Icon(Icons.check, color: style.onPrimary, size: 14),
              )
            : Container(
                key: const Key('Unselected'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: style.primaryHighlightDark.darken(darken),
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

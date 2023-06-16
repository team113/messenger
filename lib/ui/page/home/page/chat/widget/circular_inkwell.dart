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

import '/themes.dart';

/// Widget which returns an [InkWell] circular button with an [child].
@Deprecated('This widget is not used.')
class CircularInkWell extends StatelessWidget {
  const CircularInkWell({super.key, this.child, this.onTap});

  /// [Widget] to display.
  final Widget? child;

  /// Callback, called when this [CircularInkWell] is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Material(
      type: MaterialType.circle,
      color: style.colors.onPrimary,
      shadowColor: style.colors.onBackgroundOpacity27,
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle),
          width: 42,
          height: 42,
          child: Center(child: child),
        ),
      ),
    );
  }
}

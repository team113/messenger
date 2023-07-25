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

/// Button-styled [Icon] used to expand or collapse a section of content.
class ExpandButton extends StatelessWidget {
  const ExpandButton({
    super.key,
    this.height,
    this.onTap,
    this.inverted = false,
  });

  /// Height of this [ExpandButton].
  final double? height;

  /// Indicator whether the icon of this [ExpandButton] should be inverted.
  final bool inverted;

  /// Callback, called when this [ExpandButton] is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: Icon(
              inverted ? Icons.fullscreen_exit : Icons.fullscreen,
              color: style.colors.onPrimary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

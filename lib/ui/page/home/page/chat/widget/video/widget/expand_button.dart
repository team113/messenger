// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/ui/widget/svg/svg.dart';

/// Button-styled fullscreen [Icon].
class ExpandButton extends StatelessWidget {
  const ExpandButton({
    super.key,
    this.height,
    this.onTap,
    this.fullscreen = false,
  });

  /// Height of this [ExpandButton].
  final double? height;

  /// Indicator whether fullscreen mode is enabled.
  final bool fullscreen;

  /// Callback, called when this [ExpandButton] is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: SvgIcon(
              fullscreen
                  ? SvgIcons.fullscreenExitSmall
                  : SvgIcons.fullscreenEnterSmall,
            ),
          ),
        ),
      ),
    );
  }
}

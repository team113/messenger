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

/// [Widget] which returns the fullscreen toggling button.
class ExpandButton extends StatelessWidget {
  const ExpandButton({
    super.key,
    this.height,
    this.onTap,
    this.isFullscreen = false,
  });

  /// Indicator whether this video is in fullscreen mode.
  final bool isFullscreen;

  /// Height of this [ExpandButton].
  final double? height;

  /// Callback, called when this [ExpandButton] is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Center(
          child: Icon(
            isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: style.colors.onPrimary,
            size: 21,
          ),
        ),
      ),
    );
  }
}

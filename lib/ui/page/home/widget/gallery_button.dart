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

import '/themes.dart';
import '/ui/page/call/widget/round_button.dart';
import '/ui/widget/svg/svgs.dart';

/// [RoundFloatingButton] styled to be used in [GalleryPopup] overlay.
class GalleryButton extends StatelessWidget {
  const GalleryButton({
    super.key,
    this.child,
    this.icon,
    this.onPressed,
  });

  /// Optional [Widget] to display.
  final Widget? child;

  /// [SvgData] to display.
  ///
  /// Only meaningful, if [child] is not specified.
  final SvgData? icon;

  /// Callback, called when this [GalleryButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return SizedBox(
      width: 60,
      height: 60,
      child: RoundFloatingButton(
        color: style.colors.onSecondaryOpacity50,
        onPressed: onPressed,
        withBlur: true,
        icon: icon,
        child: child,
      ),
    );
  }
}

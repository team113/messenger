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

/// Simple [GestureDetector]-based button without any decorations.
class WidgetButton extends StatelessWidget {
  const WidgetButton({
    Key? key,
    required this.child,
    this.behavior,
    this.onPressed,
  }) : super(key: key);

  /// [Widget] to press.
  final Widget child;

  /// [HitTestBehavior] of this [WidgetButton].
  final HitTestBehavior? behavior;

  /// Callback, called when the [child] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<Style>()!;
    return MouseRegion(
      cursor: onPressed == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        behavior: behavior,
        child: Container(
          color: style.transparent,
          child: child,
        ),
      ),
    );
  }
}
